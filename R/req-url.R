
req_query_set <- function(req, ...) {
  query <- list2(...)
  req$url$query <- utils::modifyList(req$url$query, query)
  req
}


req_url_get <- function(req) {
  httr::build_url(req$url)
}


req_url_set <- function(req, url) {
  req$url <- httr::parse_url(url)
  req
}

req_path_set <- function(req, path) {
  req$url$path <- path
  req
}

req_path_append <- function(req, path) {
  req$url$path <- paste0(req$url$path, "/", path)
  req
}
