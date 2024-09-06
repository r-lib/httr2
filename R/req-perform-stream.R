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
#' `r lifecycle::badge("experimental")`
#'
#' Use `req_perform_connection()` to perform a request if you want to stream the
#' response body. A response returned by `req_perform_connection()` includes a
#' connection as the body. You can then use [resp_stream_raw()],
#' [resp_stream_lines()], or [resp_stream_sse()] to retrieve data a chunk at a
#' time. Always finish up by closing the connection by calling
#' `close(response)`.
#'
#' This is an alternative interface to [req_perform_stream()] that returns a
#' [connection][base::connections] that you can use to pull the data, rather
#' than providing callbacks that the data is pushed to. This is useful if you
#' want to do other work in between handling inputs from the stream.
#'
#' @inheritParams req_perform_stream
#' @param blocking When retrieving data, should the connection block and wait
#'   for the desired information or immediately return what it has (possibly
#'   nothing)?
#' @export
#' @examples
#' req <- request(example_url()) |>
#'   req_url_path("/stream-bytes/32768")
#' resp <- req_perform_connection(req)
#'
#' length(resp_stream_raw(resp, kb = 16))
#' length(resp_stream_raw(resp, kb = 16))
#' # When the stream has no more data, you'll get an empty result:
#' length(resp_stream_raw(resp, kb = 16))
#'
#' # Always close the response when you're done
#' close(resp)
req_perform_connection <- function(req, blocking = TRUE) {
  check_request(req)
  check_bool(blocking)

  handle <- req_handle(req)
  the$last_request <- req

  tries <- 0
  delay <- 0
  max_tries <- retry_max_tries(req)
  deadline <- Sys.time() + retry_max_seconds(req)
  resp <- NULL
  while (tries < max_tries && Sys.time() < deadline) {
    sys_sleep(delay, "for retry backoff")

    if (!is.null(resp)) {
      close(resp$body)
    }
    resp <- req_perform_connection1(req, handle, blocking = blocking)

    if (retry_is_transient(req, resp)) {
      tries <- tries + 1
      delay <- retry_after(req, resp, tries)
    } else {
      break
    }
  }

  if (error_is_error(req, resp)) {
    # Read full body if there's an error
    conn <- resp$body
    resp$body <- read_con(conn)
    close(conn)
  }
  the$last_response <- resp
  handle_resp(req, resp)

  resp
}

req_perform_connection1 <- function(req, handle, blocking = TRUE) {
  stream <- curl::curl(req$url, handle = handle)

  # Must open the stream in order to initiate the connection
  open(stream, "rbf", blocking = blocking)
  curl_data <- curl::handle_data(handle)

  new_response(
    method = req_method_get(req),
    url = curl_data$url,
    status_code = curl_data$status_code,
    headers = as_headers(curl_data$headers),
    body = stream,
    request = req
  )
}

#' Read a streaming body a chunk at a time
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' * `resp_stream_raw()` retrieves bytes (`raw` vectors).
#' * `resp_stream_lines()` retrieves lines of text (`character` vectors).
#' * `resp_stream_sse()` retrieves [server-sent
#'   events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events)
#'   from the stream. It currently only works with text mode connections so when calling
#'   `req_perform_connection()` you must use `mode = "text"`.
#'
#' @returns
#' * `resp_stream_raw()`: a raw vector.
#' * `resp_stream_lines()`: a character vector.
#' * `resp_stream_sse()`: a list with components `type`, `data`, and `id`; or
#'   `NULL`, signifying that the end of the stream has been reached or--if in
#'   nonblocking mode--that no event is currently available.
#' @export
#' @param resp,con A streaming [response] created by [req_perform_connection()].
#' @param kb How many kilobytes (1024 bytes) of data to read.
resp_stream_raw <- function(resp, kb = 32) {
  check_streaming_response(resp)
  conn <- resp$body

  readBin(conn, raw(), kb * 1024)
}

find_line_boundary <- function(buffer) {
  if (length(buffer) == 0) {
    return(NULL)
  }

  # Look left 1 byte
  right1 <- c(tail(buffer, -1), 0x00)

  crlf <- buffer == 0x0D & right1 == 0x0A
  cr <- buffer == 0x0D
  lf <- buffer == 0x0A
  
  all <- which(crlf | cr | lf)
  if (length(all) == 0) {
    return(NULL)
  }

  first <- all[[1]]
  if (crlf[first]) {
    return(first + 2)
  } else {
    return(first + 1)
  }
}

#' @export
#' @rdname resp_stream_raw
#' @param lines The maximum number of lines to return at once.
#' @param warn Like [readLines()]: warn if the connection ends without a final
#'   EOL.
resp_stream_lines <- function(resp, lines = 1, max_size = Inf, warn = TRUE) {
  check_streaming_response(resp)
  check_number_whole(lines, min = 0, allow_infinite = TRUE)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)
  check_logical(warn)

  if (lines == 0) {
    # If you want to do that, who am I to judge?
    return(character())
  }

  lines_read <- character(0)
  while (lines > 0) {
    line <- resp_stream_oneline(resp, max_size, warn)
    if (length(line) == 0) {
      # No more data, either because EOF or req_perform_connection(blocking=FALSE).
      # Either way, return what we have
      return(lines_read)
    }
    lines_read <- c(lines_read, line)
    lines <- lines - 1
  }
  lines_read
}

resp_stream_oneline <- function(resp, max_size, warn) {
  repeat {
    line_bytes <- resp_boundary_pushback(resp, max_size, find_line_boundary, include_trailer = TRUE)
    if (is.null(line_bytes)) {
      return(character())
    }

    eat_next_lf <- resp$cache$resp_stream_oneline_eat_next_lf
    resp$cache$resp_stream_oneline_eat_next_lf <- FALSE
    
    if (identical(line_bytes, as.raw(0x0A)) && isTRUE(eat_next_lf)) {
      # We hit that special edge case, see below
      next
    }

    # If ending on \r, there's a special edge case here where if the
    # next line begins with \n, that byte should be eaten.
    if (tail(line_bytes, 1) == 0x0D) {
      resp$cache$resp_stream_oneline_eat_next_lf <- TRUE
    }

    # Use `resp$body` as the variable name so that if warn=TRUE, you get
    # "incomplete final line found on 'resp$body'" as the warning message
    `resp$body` <- line_bytes
    line_con <- rawConnection(`resp$body`)
    on.exit(close(line_con))
    # TODO: Use iconv to convert from whatever encoding is specified in the
    # response header, to UTF-8
    return(readLines(line_con, n = 1, warn = warn))
  }
}

# Slices the vector using the only sane semantics: start inclusive, end
# exclusive.
#
# * Allows start == end, which means return no elements.
# * Allows start == length(vector) + 1, which means return no elements.
# * Allows zero-length vectors.
#
# Otherwise, slice() is quite strict about what it allows start/end to be: no
# negatives, no reversed order.
slice <- function(vector, start = 1, end = length(vector) + 1) {
  stopifnot(start > 0)
  stopifnot(start <= length(vector) + 1)
  stopifnot(end > 0)
  stopifnot(end <= length(vector) + 1)
  stopifnot(end >= start)

  if (start == end) {
    vector[FALSE] # Return an empty vector of the same type
  } else {
    vector[start:(end - 1)]
  }
}

# Function to find the first double line ending in a buffer, or NULL if no
# double line ending is found
#
# Example:
#   find_event_boundary(charToRaw("data: 1\n\nid: 12345"))
# Returns:
#   list(
#     matched = charToRaw("data: 1\n\n"),
#     remaining = charToRaw("id: 12345")
#   )
find_event_boundary <- function(buffer) {
  if (length(buffer) < 2) {
    return(NULL)
  }

  # leftX means look behind by X bytes. For example, left1[2] equals buffer[1].
  # Any attempt to read past the beginning of the buffer results in 0x00.
  left1 <- c(0x00, head(buffer, -1))
  left2 <- c(0x00, head(left1, -1))
  left3 <- c(0x00, head(left2, -1))

  boundary_end <- which(
    (left1 == 0x0A & buffer == 0x0A) | # \n\n
    (left1 == 0x0D & buffer == 0x0D) | # \r\r
    (left3 == 0x0D & left2 == 0x0A & left1 == 0x0D & buffer == 0x0A) # \r\n\r\n
  )
  
  if (length(boundary_end) == 0) {
    return(NULL)  # No event boundary found
  }

  boundary_end <- boundary_end[1]  # Take the first occurrence
  split_at <- boundary_end + 1  # Split at one after the boundary
  split_at
}

# Splits a buffer into the part before `split_at`, and the part starting at
# `split_at`. It's possible for either of the returned parts to be zero-length
# (i.e. if `split_at` is 1 or length(buffer)+1).
split_buffer <- function(buffer, split_at) {
  # Return a list with the event data and the remaining buffer
  list(
    matched = slice(buffer, end = split_at),
    remaining = slice(buffer, start = split_at)
  )
}

# @param max_size Maximum number of bytes to look for a boundary before throwing an error
# @param boundary_func A function that takes a raw vector and returns NULL if no
#   boundary was detected, or one position PAST the end of the first boundary in
#   the vector
# @param include_trailer If TRUE, at the end of the response, if there are
#   bytes after the last boundary, then return those bytes; if FALSE, then those
#   bytes are silently discarded.
resp_boundary_pushback <- function(resp, max_size, boundary_func, include_trailer) {
  check_streaming_response(resp)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)

  chunk_size <- min(max_size + 1, 1024)

  # Grab data left over from last resp_stream_sse() call (if any)
  buffer <- resp$cache$push_back %||% raw()
  resp$cache$push_back <- raw()

  print_buffer <- function(buf, label) {
    # cat(label, ":", paste(sprintf("%02X", as.integer(buf)), collapse = " "), "\n", file = stderr())
  }

  # Read chunks until we find an event or reach the end of input
  repeat {
    # Try to find an event boundary using the data we have
    print_buffer(buffer, "Buffer to parse")
    split_at <- boundary_func(buffer)

    if (!is.null(split_at)) {
      result <- split_buffer(buffer, split_at)
      # We found a complete event
      print_buffer(result$matched, "Matched data")
      print_buffer(result$remaining, "Remaining buffer")
      resp$cache$push_back <- result$remaining
      return(result$matched)
    }
    
    if (length(buffer) > max_size) {
      # Keep the buffer in place, so that if the user tries resp_stream_sse
      # again, they'll get the same error rather than reading the stream
      # having missed a bunch of bytes.
      resp$cache$push_back <- buffer
      cli::cli_abort("Streaming read exceeded size limit of {max_size}")
    }

    # We didn't have enough data. Attempt to read more
    chunk <- readBin(resp$body, raw(),
      # Don't let us exceed the max size by more than one byte; we do allow the
      # one extra byte so we know to error.
      n = min(chunk_size, max_size - length(buffer) + 1)
    )

    print_buffer(chunk, "Received chunk")

    # If we've reached the end of input, store the buffer and return NULL
    if (length(chunk) == 0) {
      if (!isIncomplete(resp$body)) {
        # We've truly reached the end of the connection; no more data is coming
        if (include_trailer && length(buffer) > 0) {
          return(buffer)
        } else {
          return(NULL)
        }
      }
      
      # More data might come later
      print_buffer(buffer, "Storing incomplete buffer")
      resp$cache$push_back <- buffer
      return(NULL)
    }
    
    # More data was received; combine it with existing buffer and continue the
    # loop to try parsing again
    buffer <- c(buffer, chunk)
    print_buffer(buffer, "Combined buffer")
  }
}

#' @param max_size The maximum number of bytes to buffer; once this number of
#'   bytes has been exceeded without a line/event boundary, an error is thrown.
#' @export
#' @rdname resp_stream_raw
# TODO: max_size
resp_stream_sse <- function(resp, max_size = Inf) {
  event_bytes <- resp_boundary_pushback(resp, max_size, find_event_boundary, include_trailer = FALSE)
  if (!is.null(event_bytes)) {
    parse_event(event_bytes)
  } else {
    return(NULL)
  }
}

#' @export
#' @param ... Not used; included for compatibility with generic.
#' @rdname resp_stream_raw
close.httr2_response <- function(con, ...) {
  check_response(con)

  if (inherits(con$body, "connection") && isValid(con$body)) {
    close(con$body)
  }

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


parse_event <- function(event_data) {
  # always treat event_data as UTF-8, it's in the spec
  str_data <- rawToChar(event_data)
  Encoding(str_data) <- "UTF-8"

  # The spec says \r\n, \r, and \n are all valid separators
  lines <- strsplit(str_data, "\r\n|\r|\n")[[1]]

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
