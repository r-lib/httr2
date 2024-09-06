#' Set and preserve cookies
#'
#' @description
#' Use `req_cookie_set()` to set client side cookies that are sent to the
#' server.
#'
#' By default, httr2 uses a clean slate for every request meaning that cookies
#' are not automatically preserved across requests. To preserve cookies, use
#' `req_cookie_preserve()` along with the path to cookie file that will be
#' read before and updated after each request.
#'
#' @inheritParams req_perform
#' @param path A path to a file where cookies will be read from before and updated after the request.
#' @export
#' @examples
#' # Use `req_cookies_set()` to set client-side cookies
#' request(example_url()) |>
#'   req_cookies_set(a = 1, b = 1) |>
#'   req_dry_run()
#'
#' # Use `req_cookie_preserve()` to preserve server-side cookies across requests
#' path <- tempfile()
#'
#' # Set a server-side cookie
#' request(example_url()) |>
#'   req_cookie_preserve(path) |>
#'   req_template("/cookies/set/:name/:value", name = "chocolate", value = "chip") |>
#'   req_perform() |>
#'   resp_body_json()
#'
#' # Set another sever-side cookie
#' request(example_url()) |>
#'   req_cookie_preserve(path) |>
#'   req_template("/cookies/set/:name/:value", name = "oatmeal", value = "raisin") |>
#'   req_perform() |>
#'   resp_body_json()
#'
#' # Add a client side cookie
#' request(example_url()) |>
#'   req_url_path("/cookies/set") |>
#'   req_cookie_preserve(path) |>
#'   req_cookies_set(snicker = "doodle") |>
#'   req_perform() |>
#'   resp_body_json()
#'
#' # The cookie path has a straightforward format
#' cat(readChar(path, nchars = 1e4))
req_cookie_preserve <- function(req, path) {
  check_request(req)
  check_string(path, allow_empty = FALSE)

  req_options(req, cookiejar = path, cookiefile = path)
}

#' @export
#' @rdname req_cookie_preserve
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]>
#'   Name-value pairs that define query parameters. Each value must be
#'   an atomic vector, which is automatically escaped. To opt-out of escaping,
#'   wrap strings in `I()`.
req_cookies_set <- function(req, ...) {
  check_request(req)
  req_options(req, cookie = cookies_build(list2(...)))
}

cookies_build <- function(x, error_call = caller_env()) {
  elements_build(x, "Cookies", ";", error_call = error_call)
}
