
req_headers_set <- function(req, ...) {
  headers <- list2(...)
  req$headers <- utils::modifyList(req$headers, headers)
  req
}

req_content_type <- function(req, type, path = NULL, default = NULL) {
  type <- type %||% mime::guess_type(path, empty = NULL) %||% default
  req_headers_set(req, "Content-Type" = type)
}
