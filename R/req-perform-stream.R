
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
#' @param round round the raw vector that is sent to `callback` to the
#'   last "byte" or "line".
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
req_perform_stream <- function(req, callback, timeout_sec = Inf, buffer_kb = 64, round = c("byte", "line")) {
  check_request(req)

  handle <- req_handle(req)
  callback <- as_function(callback)
  round <- as_round_function(round)

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
      cut <- as.integer(round(buf))
      if (length(cut)) {
        continue <- isTRUE(callback(head(buf, n = cut)))
        buf <- tail(buf, n = -cut)
      }
    } else {
      continue <- incomplete
    }
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

round_byte <- function(bytes) {
  length(bytes)
}

round_line <- function(bytes) {
  new_lines <- which(bytes == charToRaw("\n"))
  # this returns integer(0) when there are no newline
  new_lines[length(new_lines)]
}

as_round_function <- function(round = c("byte", "line"), error_call = caller_env()) {
  if (is.function(round)) {
    round
  } else if (is.character(round)) {
    round <- match.arg(round)
    switch(round,
      byte = round_byte,
      line = round_line
    )
  } else {
    cli::cli_abort('{.arg round} must "byte", "line" or a function', call = error_call)
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
