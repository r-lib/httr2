#' Modify URL path
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' * `req_url_path()` modifies the path.
#' * `req_url_path_append()` adds to the path.
#'
#' Please use [req_url_relative()] instead.
#'
#' @inheritParams req_perform
#' @param ... For `req_url_path()` and `req_url_path_append()`: A sequence of
#'   path components that will be combined with `/`.
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' req <- request("http://example.com/a/b/c")
#'
#' # OLD
#' req |> req_url_path("/d/e/f")
#' req |> req_url_path_append("d/e/f")
#'
#' # NEW
#' req |> req_url_relative("/d/e/f")
#' req |> req_url_relative("d/e/f")
req_url_path <- function(req, ...) {
  lifecycle::deprecate_soft("1.1.0", "req_url_path()", "req_url_relative()")

  check_request(req)
  path <- dots_to_path(...)

  req_url(req, url_modify(req$url, path = path))
}

#' @export
#' @rdname req_url_path
req_url_path_append <- function(req, ...) {
  lifecycle::deprecate_soft("1.1.0", "req_url_path_append()", "req_url_relative()")

  check_request(req)
  path <- dots_to_path(...)

  url <- url_parse(req$url)
  url$path <- paste0(sub("/$", "", url$path), path)

  req_url(req, url_build(url))
}

dots_to_path <- function(...) {
  path <- paste(c(...), collapse = "/")
  # Ensure we don't add duplicate /s
  # NB: also keeps "" unchanged.
  sub("^([^/])", "/\\1", path)
}
