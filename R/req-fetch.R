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
  url <- req_url_get(req)
  handle <- handle %||% req_handle(req)

  if (!is.null(path)) {
    res <- curl::curl_fetch_disk(url, path, handle)
    body <- new_path(path)
  } else {
    res <- curl::curl_fetch_memory(url, handle)
    body <- res$content
  }

  new_response(
    handle = handle,
    url = res$url,
    status_code = res$status_code,
    headers = curl::parse_headers_list(res$headers),
    body = body,
    times = res$times
  )
}


req_stream <- function(req, callback, timeout = Inf, buffer_kb = 64) {
  url <- req_url_get(req)
  handle <- req_handle(req)
  callback <- as_function(callback)

  stopifnot(is.numeric(timeout), timeout > 0)
  stop_time <- Sys.time() + timeout

  stream <- curl::curl(url, handle = handle)
  open(stream, "rb")
  withr::defer(close(stream))

  continue <- TRUE
  while(continue && isIncomplete(stream) && Sys.time() < stop_time) {
    buf <- readBin(stream, raw(), buffer_kb * 1024)
    if (length(buf) > 0) {
      continue <- isTRUE(callback(buf))
    }
  }

  res <- curl::handle_data(handle)

  new_response(
    url = res$url,
    status_code = res$status_code,
    headers = curl::parse_headers_list(res$headers),
    body = res$content,
    times = res$times
  )
}

req_handle <- function(req) {
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
