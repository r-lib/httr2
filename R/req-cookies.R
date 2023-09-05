#' Preserve cookies across requests
#'
#' By default, httr2 uses a clean slate for every request meaning that cookies
#' are not automatically preserved across requests. To preserve cookies, you
#' must set a cookie file which will be read before and updated after each
#' request.
#'
#' @inheritParams req_perform
#' @param path A path to a file where cookies will be read from before and updated after the request.
#' @export
#' @examples
#' path <- tempfile()
#' httpbin <- request(example_url()) %>%
#'   req_cookie_preserve(path)
#'
#' # Manually set two cookies
#' httpbin %>%
#'   req_template("/cookies/set/:name/:value", name = "chocolate", value = "chip") %>%
#'   req_perform() %>%
#'   resp_body_json()
#'
#' httpbin %>%
#'   req_template("/cookies/set/:name/:value", name = "oatmeal", value = "raisin") %>%
#'   req_perform() %>%
#'   resp_body_json()
#'
#' # The cookie path has a straightforward format
#' cat(readChar(path, nchars = 1e4))
req_cookie_preserve <- function(req, path) {
  check_request(req)
  check_string(path, allow_empty = FALSE)

  req_options(req,
    cookiejar = path,
    cookiefile = path
  )
}

