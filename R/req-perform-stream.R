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

  stream <- curl::curl(req$url, handle = handle)
  open(stream, "rbf")
  withr::defer(close(stream))

  res <- curl::handle_data(handle)
  the$last_request <- req

  # Return early if there's a problem
  resp <- new_response(
    method = req_method_get(req),
    url = res$url,
    status_code = res$status_code,
    headers = as_headers(res$headers),
    body = NULL,
    request = req
  )
  if (error_is_error(req, resp)) {
    resp$body <- read_con(stream)
    the$last_response <- resp
    handle_resp(req, resp)
  }

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

  the$last_response <- resp
  resp
}


#' @export
req_perform_open <- function(req, blocking = TRUE) {

  check_request(req)

  handle <- req_handle(req)

  stream <- curl::curl(req$url, handle = handle)
  open(stream, "rbf", blocking = blocking)

  res <- curl::handle_data(handle)
  the$last_request <- req

  # Return early if there's a problem
  resp <- new_response(
    method = req_method_get(req),
    url = res$url,
    status_code = res$status_code,
    headers = as_headers(res$headers),
    body = NULL,
    request = req
  )
  the$last_repsonse <- resp
  if (error_is_error(req, resp)) {
    resp$body <- read_con(stream)
    handle_resp(req, resp)
  } else {
    resp$body <- stream
    resp
  }
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
