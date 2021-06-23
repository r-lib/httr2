#' Modify request URL
#'
#' @description
#' * `req_url()` replaces the entire url
#' * `req_url_query()` modifies the components of the query
#' * `req_url_path()` modifies the path
#' * `req_url_path_append()` adds to the path
#'
#' @inheritParams req_perform
#' @param url New URL; completely replaces existing.
#' @return A modified HTTP [request].
#' @export
#' @examples
#' req <- request("http://example.com")
#'
#' # Change url components
#' req %>%
#'   req_url_path_append("a") %>%
#'   req_url_path_append("b") %>%
#'   req_url_path_append("search.html") %>%
#'   req_url_query(q = "the cool ice")
#'
#' # Change complete url
#' req %>%
#'   req_url("http://google.com")
req_url <- function(req, url) {
  check_request(req)
  check_string(url, "`url`")

  req$url <- url
  req
}

#' @export
#' @rdname req_url
#' @param ... Name-value pairs that provide query parameters.
req_url_query <- function(req, ...) {
  check_request(req)
  req_url(req, url_modify(req$url, query = list2(...)))
}

#' @export
#' @rdname req_url
#' @param path Path to replace or append to existing path.
req_url_path <- function(req, path) {
  check_request(req)
  check_string(path, "`path`")
  if (!grepl("^/", path)) {
    path <- paste0("/", path)
  }

  req_url(req, url_modify(req$url, path = path))
}

#' @export
#' @rdname req_url
req_url_path_append <- function(req, path) {
  check_request(req)
  check_string(path, "`path`")

  url <- url_parse(req$url)

  if (!grepl("^/", path) && (is.null(url$path) || !grepl("/$", url$path))) {
    path <- paste0("/", path)
  }

  url$path <- paste0(url$path, path)
  req_url(req, url_build(url))
}
