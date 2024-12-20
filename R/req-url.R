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
#' @param ... For `req_url_query()`: <[`dynamic-dots`][rlang::dyn-dots]>
#'   Name-value pairs that define query parameters. Each value must be either
#'   an atomic vector or `NULL` (which removes the corresponding parameters).
#'   If you want to opt out of escaping, wrap strings in `I()`.
#'
#'   For `req_url_path()` and `req_url_path_append()`: A sequence of path
#'   components that will be combined with `/`.
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' req <- request("http://example.com")
#'
#' # Change url components
#' req |>
#'   req_url_path_append("a") |>
#'   req_url_path_append("b") |>
#'   req_url_path_append("search.html") |>
#'   req_url_query(q = "the cool ice")
#'
#' # Change complete url
#' req |>
#'   req_url("http://google.com")
#'
#' # Use .multi to control what happens with vector parameters:
#' req |> req_url_query(id = 100:105, .multi = "comma")
#' req |> req_url_query(id = 100:105, .multi = "explode")
#'
#' # If you have query parameters in a list, use !!!
#' params <- list(a = "1", b = "2")
#' req |>
#'   req_url_query(!!!params, c = "3")
req_url <- function(req, url) {
  check_request(req)
  check_string(url)

  req$url <- url
  req
}

#' @export
#' @rdname req_url
#' @param .multi Controls what happens when an element of `...` is a vector
#'   containing multiple values:
#'
#'   * `"error"`, the default, throws an error.
#'   * `"comma"`, separates values with a `,`, e.g. `?x=1,2`.
#'   * `"pipe"`, separates values with a `|`, e.g. `?x=1|2`.
#'   * `"explode"`, turns each element into its own parameter, e.g. `?x=1&x=2`
#'
#'   If none of these options work for your needs, you can instead supply a
#'   function that takes a character vector of argument values and returns a
#'   a single string.
req_url_query <- function(.req,
                          ...,
                          .multi = c("error", "comma", "pipe", "explode")) {
  check_request(.req)

  dots <- multi_dots(..., .multi = .multi)

  url <- url_parse(.req$url)
  url$query <- modify_list(url$query, !!!dots)
  req_url(.req, url_build(url))
}

#' @export
#' @rdname req_url
req_url_path <- function(req, ...) {
  check_request(req)
  path <- dots_to_path(...)

  req_url(req, url_modify(req$url, path = path))
}

#' @export
#' @rdname req_url
req_url_path_append <- function(req, ...) {
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
