#' Perform a request and handle data as it streams back
#'
#' @description
#' After preparing a request, call `req_perform_stream()` to perform the request
#' and handle the result with a streaming callback. This is useful for
#' streaming HTTP APIs where potentially the stream never ends.
#'
#' The `callback` will only be called if the result is successful. If you need
#' to stream an error response, you can use [req_error()] to suppress error
#' handling so that the body is streamed to you.
#'
#' @inheritParams req_perform
#' @param callback A single argument callback function. It will be called
#'   repeatedly with a raw vector whenever there is at least `buffer_kb`
#'   worth of data to process. It must return `TRUE` to continue streaming.
#' @param timeout_sec Number of seconds to process stream for.
#' @param buffer_kb Buffer size, in kilobytes.
#' @param round How should the raw vector sent to `callback` be rounded?
#'   Choose `"byte"`, `"line"`, or supply your own function that takes a
#'   raw vector of `bytes` and returns the locations of possible cut points
#'   (or `integer()` if there are none).
#' @returns An HTTP [response]. The body will be empty if the request was
#'   successful (since the `callback` function will have handled it). The body
#'   will contain the HTTP response body if the request was unsuccessful.
#' @export
#' @examples
#' show_bytes <- function(x) {
#'   cat("Got ", length(x), " bytes\n", sep = "")
#'   TRUE
#' }
#' resp <- request(example_url()) |>
#'   req_url_path("/stream-bytes/100000") |>
#'   req_perform_stream(show_bytes, buffer_kb = 32)
#' resp
req_perform_stream <- function(req,
                               callback,
                               timeout_sec = Inf,
                               buffer_kb = 64,
                               round = c("byte", "line")) {
  check_request(req)

  handle <- req_handle(req)
  check_function(callback)
  check_number_decimal(timeout_sec, min = 0)
  check_number_decimal(buffer_kb, min = 0)
  cut_points <- as_round_function(round)

  stop_time <- Sys.time() + timeout_sec

  resp <- req_perform_connection(req)
  stream <- resp$body
  withr::defer(close(stream))

  continue <- TRUE
  incomplete <- TRUE
  buf <- raw()

  while (continue && isIncomplete(stream) && Sys.time() < stop_time) {
    buf <- c(buf, readBin(stream, raw(), buffer_kb * 1024))

    if (length(buf) > 0) {
      cut <- cut_points(buf)
      n <- length(cut)
      if (n) {
        continue <- isTRUE(callback(utils::head(buf, n = cut[n])))
        buf <- utils::tail(buf, n = -cut[n])
      }
    }
  }

  # if there are leftover bytes and none of the callback()
  # returned FALSE.
  if (continue && length(buf)) {
    callback(buf)
  }

  # We're done streaming so convert to bodiless response
  resp$body <- raw()
  the$last_response <- resp
  resp
}

#' Perform a request and return a streaming connection
#'
#' @description
#' Use `req_perform_connection()` to perform a request that includes a
#' connection as the body of the response, then `resp_stream_bytes()`,
#' `resp_stream_lines()`, or `resp_stream_sse()` to retrieve data a chunk at a
#'  timen, and finish by closing the connection with `close()`.
#'
#' This is an alternative interface to [req_perform_stream()] that returns a
#' connection that you can pull from data, rather than callbacks that are called
#' as the data streams in. This is useful if you want to do other work in
#' between streaming inputs.
#'
#' @inheritParams req_perform_stream
#' @param resp,con A httr2 [response].
#' @param blocking When retrieving data, should the connection block and wait
#'   for the desired information or immediately return what it has?
#' @export
req_perform_connection <- function(req, blocking = TRUE) {
  check_request(req)
  check_bool(blocking)

  handle <- req_handle(req)

  stream <- curl::curl(req$url, handle = handle)
  open(stream, "rbf", blocking = blocking)

  res <- curl::handle_data(handle)
  the$last_request <- req

  tries <- 0
  delay <- 0
  max_tries <- retry_max_tries(req)
  deadline <- Sys.time() + retry_max_seconds(req)
  while (tries < max_tries && Sys.time() < deadline) {
    sys_sleep(delay, "for retry backoff")
    
    resp <- new_response(
      method = req_method_get(req),
      url = res$url,
      status_code = res$status_code,
      headers = as_headers(res$headers),
      body = NULL,
      request = req
    )

    if (retry_is_transient(req, resp)) {
      tries <- tries + 1
      delay <- retry_after(req, resp, tries)
    } else {
      break
    }
  }

  if (error_is_error(req, resp)) {
    # Read full body if there's an error
    resp$body <- read_con(stream)
    close(stream)
  } else {
    resp$body <- stream
  }
  the$last_response <- resp
  handle_resp(req, resp)

  resp
}

#' @export
#' @rdname req_perform_connection
#' @param kb How many kilobytes (1024 bytes) of data to read.
resp_stream_raw <- function(resp, kb = 32) {
  check_streaming_response(resp)
  conn <- resp$body

  readBin(conn, raw(), kb * 1024)
}

#' @export
#' @rdname req_perform_connection
#' @param lines How many lines to read
resp_stream_lines <- function(resp, lines = 1) {
  check_streaming_response(resp)
  conn <- resp$body

  readLines(conn, n = lines)
}

#' @export
#' @rdname req_perform_connection
# TODO: max_size
resp_stream_sse <- function(resp) {
  check_streaming_response(resp)
  conn <- resp$body

  lines <- character(0)
  while (TRUE) {
    line <- readLines(conn, n = 1)
    if (length(line) == 0) {
      break
    }
    if (line == "") {
      # \n\n detected, end of event
      return(parse_event(lines))
    }
    lines <- c(lines, line)
  }

  if (length(lines) > 0) {
    # We have a partial event, put it back while we wait
    # for more
    pushBack(lines, conn)
  }

  return(NULL)
}

#' @export
#' @param ... Not used; included for compatibility with generic.
#' @rdname req_perform_connection
close.httr2_response <- function(con, ...) {
  check_streaming_response(con)

  close(con$body)
  invisible()
}

# Helpers ----------------------------------------------------------------------

check_streaming_response <- function(resp,
                                     arg = caller_arg(resp),
                                     call = caller_env()) {

  check_response(resp, arg = arg, call = call)

  if (resp_body_type(resp) != "stream") {
    stop_input_type(
      resp,
      "a streaming HTTP response object",
      allow_null = FALSE,
      arg = arg,
      call = call
    )
  }

  if (!isValid(resp$body)) {
    cli::cli_abort("{.arg {arg}} has already been closed.", call = call)
  }
}

# isOpen doesn't work for two reasons:
# 1. It errors if con has been closed, rather than returning FALSE
# 2. If returns TRUE if con has been closed and a new connection opened
#
# So instead we retrieve the connection from its number and compare to the
# original connection. This works because connections have an undocumented
# external pointer.
isValid <- function(con) {
  tryCatch(
    identical(getConnection(con), con),
    error = function(cnd) FALSE
  )
}


parse_event <- function(lines) {
  m <- regexec("([^:]*)(: ?)?(.*)", lines)
  matches <- regmatches(lines, m)
  keys <- c("event", vapply(matches, function(x) x[2], character(1)))
  values <- c("message", vapply(matches, function(x) x[4], character(1)))

  remove_dupes <- duplicated(keys, fromLast = TRUE) & keys != "data"
  keys <- keys[!remove_dupes]
  values <- values[!remove_dupes]

  event_type <- values[keys == "event"]
  data <- values[keys == "data"]
  id <- values[keys == "id"]

  list(
    type = event_type,
    data = data,
    id = id
  )
}

as_round_function <- function(round = c("byte", "line"),
                              error_call = caller_env()) {
  if (is.function(round)) {
    check_function2(round, args = "bytes")
    round
  } else if (is.character(round)) {
    round <- arg_match(round, error_call = error_call)
    switch(round,
      byte = function(bytes) length(bytes),
      line = function(bytes) which(bytes == charToRaw("\n"))
    )
  } else {
    cli::cli_abort(
      '{.arg round} must be "byte", "line" or a function.',
      call = error_call
    )
  }
}

read_con <- function(con, buffer = 32 * 1024) {
  bytes <- raw()
  repeat {
    new <- readBin(con, "raw", n = buffer)
    if (length(new) == 0) break
    bytes <- c(bytes, new)
  }
  if (length(bytes) == 0) {
    NULL
  } else {
    bytes
  }
}

#' @export
#' @rdname req_perform_stream
#' @usage NULL
req_stream <- function(req, callback, timeout_sec = Inf, buffer_kb = 64) {
  lifecycle::deprecate_warn(
    "1.0.0",
    "req_stream()",
    "req_perform_stream()"
  )

  req_perform_stream(
    req = req,
    callback = callback,
    timeout_sec = timeout_sec,
    buffer_kb = buffer_kb
  )
}
