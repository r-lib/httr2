
req_headers_set <- function(req, ...) {
  headers <- list2(...)
  req$url$headers <- utils::modifyList(req$url$headers, headers)
  req
}
