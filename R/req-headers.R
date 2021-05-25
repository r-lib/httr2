# https://everything.curl.dev/libcurl-http/requests#customize-http-request-headers
req_headers_set <- function(req, ...) {
  headers <- list2(...)
  req$headers <- utils::modifyList(req$headers, headers)
  req
}

req_content_type <- function(req, type, path = NULL) {
  if (is.null(type) && !is.null(path)) {
    type <- mime::guess_type(path, empty = "")
  }

  req_headers_set(req, "Content-Type" = type)
}
