
#' Perform a request and handle data as it streams back
#'
#' After preparing a request, call `req_perform_stream()` to perform the request
#' and handle the result with a streaming callback. This is useful for
#' streaming HTTP APIs where potentially the stream never ends.
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
#' @returns An HTTP [response].
#' @export
#' @examples
#' show_bytes <- function(x) {
#'   cat("Got ", length(x), " bytes\n", sep = "")
#'   TRUE
#' }
#' resp <- request(example_url()) |>
#'   req_url_path("/stream-bytes/100000") |>
#'   req_perform_stream(show_bytes, buffer_kb = 32)
req_perform_stream <- function(req,
                               callback,
                               timeout_sec = Inf,
                               buffer_kb = 64,
                               round = c("byte", "line")) {
  check_request(req)

  handle <- req_handle(req)
  callback <- as_function(callback)
  cut_points <- as_round_function(round)

  stopifnot(is.numeric(timeout_sec), timeout_sec > 0)
  stop_time <- Sys.time() + timeout_sec

  stream <- curl::curl(req$url, handle = handle)
  open(stream, "rbf")
  withr::defer(close(stream))

  continue <- TRUE
  incomplete <- TRUE
  buf <- raw()
  while(continue && Sys.time() < stop_time) {
    incomplete <- isIncomplete(stream)
    if (incomplete) {
      buf <- c(buf, readBin(stream, raw(), buffer_kb * 1024))
    }

    if (length(buf) > 0) {
      # there are leftover bytes, but the stream is complete
      # break the loop so that the callback() is given the
      # whole buffer
      if (!incomplete) {
        break
      }

      cut <- cut_points(buf)
      n <- length(cut)
      if (n) {
        continue <- isTRUE(callback(head(buf, n = cut[n])))
        buf <- tail(buf, n = -cut[n])
      }
    } else {
      if (!incomplete) {
        break
      }
    }
  }

  # if there are leftover bytes and none of the callback()
  # returned FALSE.
  if (continue && length(buf)) {
    callback(buf)
  }

  data <- curl::handle_data(handle)
  new_response(
    method = req_method_get(req),
    url = data$url,
    status_code = data$status_code,
    headers = as_headers(data$headers),
    body = NULL
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
