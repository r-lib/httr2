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
#' @param ... For `req_url_query()`: Name-value pairs that provide query
#'   parameters. Each value must be either length-1 atomic vector or `NULL`
#'   (which is automatically dropped). Query values can be wrapped in `I`
#'   to escape ascii codes.
#'
#'   For `req_url_path()` and `req_url_path_append()`: A sequence of path
#'   components that will be combined with `/`.
#' @returns A modified HTTP [request].
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
req_url_query <- function(.req, ...) {
  check_request(.req)

  url <- url_parse(.req$url)
  url$query <- modify_list(url$query, ...)

  req_url(.req, url_build(url))
}

#' @export
#' @rdname req_url
req_url_path <- function(req, ...) {
  check_request(req)
  path <- paste(..., sep = "/")

  if (!grepl("^/", path)) {
    path <- paste0("/", path)
  }

  req_url(req, url_modify(req$url, path = path))
}

#' @export
#' @rdname req_url
req_url_path_append <- function(req, ...) {
  check_request(req)
  path <- paste(..., sep = "/")

  url <- url_parse(req$url)

  # Ensure we don't add duplicate /s
  if (!grepl("^/", path)) {
    path <- paste0("/", path)
  }
  url$path <- paste0(sub("/$", "", url$path), path)

  req_url(req, url_build(url))
}
