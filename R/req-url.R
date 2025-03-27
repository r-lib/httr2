#' Modify request URL
#'
#' @description
#' * `req_url()` replaces the entire URL.
#' * `req_url_relative()` navigates to a relative URL.
#' * `req_url_query()` modifies individual query components.
#' * `req_url_path()` modifies just the path.
#' * `req_url_path_append()` adds to the path.
#'
#' @seealso
#' * To modify a URL without creating a request, see [url_modify()] and
#'   friends.
#' * To use a template like `GET /user/{user}`, see [req_template()].
#' @inheritParams req_perform
#' @param url A new URL; either an absolute URL for `req_url()` or a
#'   relative URL for `req_url_relative()`.
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
#' # Change complete url
#' req <- request("http://example.com")
#' req |> req_url("http://google.com")
#'
#' # Use a relative url
#' req <- request("http://example.com/a/b/c")
#' req |> req_url_relative("..")
#' req |> req_url_relative("/d/e/f")
#'
#' # Change url components
#' req |>
#'   req_url_path_append("a") |>
#'   req_url_path_append("b") |>
#'   req_url_path_append("search.html") |>
#'   req_url_query(q = "the cool ice")
#'
#' # Modify individual query parameters
#' req <- request("http://example.com?a=1&b=2")
#' req |> req_url_query(a = 10)
#' req |> req_url_query(a = NULL)
#' req |> req_url_query(c = 3)
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
req_url_relative <- function(req, url) {
  check_request(req)
  req_url(req, url_modify_relative(req$url, url))
}

#' @export
#' @rdname req_url
#' @inheritParams url_modify_query
req_url_query <- function(
  .req,
  ...,
  .multi = c("error", "comma", "pipe", "explode"),
  .space = c("percent", "form")
) {
  check_request(.req)
  url <- url_modify_query(.req$url, ..., .multi = .multi, .space = .space)
  req_url(.req, url)
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
