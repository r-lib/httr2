#' Perform a request and handle data as it streams back
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' Please use [req_perform_connection()] instead.
#'
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
#' # PREVIOSULY
#' show_bytes <- function(x) {
#'   cat("Got ", length(x), " bytes\n", sep = "")
#'   TRUE
#' }
#' resp <- request(example_url()) |>
#'   req_url_path("/stream-bytes/100000") |>
#'   req_perform_stream(show_bytes, buffer_kb = 32)
#'
#' # NOW
#' resp <- request(example_url()) |>
#'   req_url_path("/stream-bytes/100000") |>
#'   req_perform_connection()
#' while (!resp_stream_is_complete(resp)) {
#'   x <-  resp_stream_raw(resp, kb = 32)
#'   cat("Got ", length(x), " bytes\n", sep = "")
#' }
#' close(resp)
req_perform_stream <- function(
  req,
  callback,
  timeout_sec = Inf,
  buffer_kb = 64,
  round = c("byte", "line")
) {
  # soft deprecated because quite a few packages use it, and it was our
  # recommended approach for a while
  lifecycle::deprecate_soft(
    when = "1.2.0",
    what = "req_perform_stream()",
    with = "req_perform_connection()"
  )

  check_request(req)

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

# Helpers ----------------------------------------------------------------------

as_round_function <- function(
  round = c("byte", "line"),
  error_call = caller_env()
) {
  if (is.function(round)) {
    check_function2(round, args = "bytes")
    round
  } else if (is.character(round)) {
    round <- arg_match(round, error_call = error_call)
    switch(
      round,
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
