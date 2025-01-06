#' Modify request URL
#'
#' @description
#' * `req_url()` replaces the entire URL.
#' * `req_url_relative()` changes the relative path.
#' * `req_url_query()` modifies individual query parameters.
#'
#' @seealso
#' * To modify a URL without creating a request, see [url_modify()] and
#'   friends.
#' * To use a template like `GET /user/{user}`, see [req_template()].
#' @inheritParams req_perform
#' @param url New URL; completely replaces existing.
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]>
#'   Name-value pairs that define query parameters. Each value must be either
#'   an atomic vector or `NULL` (which removes the corresponding parameters).
#'   If you want to opt out of escaping, wrap strings in `I()`.
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
req_url_query <- function(.req,
                          ...,
                          .multi = c("error", "comma", "pipe", "explode"),
                          .space = c("percent", "form")) {
  check_request(.req)
  url <- url_modify_query(.req$url, ..., .multi = .multi, .space = .space)
  req_url(.req, url)
}
