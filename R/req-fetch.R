#' Perform a request, fetching data back to R
#'
#' After preparing a request, call `req_fetch()` to perform it, fetching
#' the results back to R.
#'
#' @param req A [req]uest.
#' @param path Optionally, path to save body of request. This is useful for
#'   large responses since it avoids storing the response in memory.
#' @param handle Advanced use only; a curl handle.
#' @returns Returns an HTTP response.
#' @export
#' @examples
#' req("https://google.com") %>%
#'   req_fetch()
req_fetch <- function(req, path = NULL, handle = NULL) {
  handle <- handle %||% req_handle(req)

  if (!is.null(path)) {
    res <- curl::curl_fetch_disk(req$url, path, handle)
    body <- new_path(path)
  } else {
    res <- curl::curl_fetch_memory(req$url, handle)
    body <- res$content
  }

  new_response(
    handle = handle,
    method = req$method %||% default_method(req),
    url = res$url,
    status_code = res$status_code,
    headers = curl::parse_headers_list(res$headers),
    body = body,
    times = res$times
  )
}

#' Perform a request, streaming data back to R
#'
#' After preparing a request, call `req_stream()` to perform the request
#' and handle the result with a streaming callback. This is useful for
#' streaming HTTP APIs where potentially the stream never ends.
#'
#' @inheritParams req_fetch
#' @param callback A single argument callback function. It will be called
#'   repeatedly with a raw vector whenever there is at least `buffer_kb`
#'   worth of data to process. It must return `TRUE` to continue streaming.
#' @param timeout_sec Number of seconds to processs stream for.
#' @param buffer_kb Buffer size, in kilobytes.
#' @export
#' @examples
#' show_bytes <- function(x) {
#'   cat("Got ", length(x), " bytes\n", sep = "")
#'   TRUE
#' }
#' req("http://httpbin.org/stream-bytes/100000") %>%
#'   req_stream(show_bytes, buffer_kb = 32)
req_stream <- function(req, callback, timeout_sec = Inf, buffer_kb = 64) {
  handle <- req_handle(req)
  callback <- as_function(callback)

  stopifnot(is.numeric(timeout_sec), timeout_sec > 0)
  stop_time <- Sys.time() + timeout_sec

  stream <- curl::curl(req$url, handle = handle)
  open(stream, "rb")
  withr::defer(close(stream))

  continue <- TRUE
  while(continue && isIncomplete(stream) && Sys.time() < stop_time) {
    buf <- readBin(stream, raw(), buffer_kb * 1024)
    if (length(buf) > 0) {
      continue <- isTRUE(callback(buf))
    }
  }

  data <- curl::handle_data(handle)
  new_response(
    handle = handle,
    url = data$url,
    status_code = data$status_code,
    headers = curl::parse_headers_list(data$headers),
    body = NULL,
    times = data$times
  )
}

req_handle <- function(req) {
  if (!is.null(req$method)) {
    req <- switch(req$method,
      HEAD = req_options_set(req, nobody = TRUE),
      req_options_set(req, customrequest = req$method)
    )
  }

  if (!has_name(req$options, "useragent")) {
    req <- req_user_agent(req, default_ua())
  }

  handle <- curl::new_handle()
  curl::handle_setheaders(handle, .list = req$headers)
  curl::handle_setopt(handle, .list = req$options)
  if (length(req$fields) > 0) {
    curl::handle_setform(handle, .list = req$fields)
  }

  handle
}

new_path <- function(x) structure(x, class = "httr_path")
is_path <- function(x) inherits(x, "httr_path")
