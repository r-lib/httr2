#' Authenticate request with HTTP basic authentication
#'
#' This sets the Authorization header. See details at
#' <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>.
#'
#' @inheritParams req_fetch
#' @param user_name,password User name and password pair.
#' @export
#' @examples
#' request("http://example.com") %>%
#'   req_auth_basic("hadley", "my-secret-password") %>%
#'   req_dry_run()
#'
#' # Note that the authorization header is not encrypted and the
#' # password can easily be restored:
#' rawToChar(jsonlite::base64_dec("aGFkbGV5Om15LXNlY3JldC1wYXNzd29yZA=="))
#' # This means that you should be careful when sharing any code that
#' # reveals the Authorization header
req_auth_basic <- function(req, user_name, password) {
  check_request(req)
  check_string(user_name, "`user_name`")
  check_string(password, "`password`")

  req_options(req,
    httpauth = auth_flags("basic"),
    userpwd = paste0(user_name, ":", password)
  )
}

#' Authenticate request with bearer token
#'
#' A bearer token gives the bearer access to confidential resources
#' (so you should keep them secure like you would with a user name and
#' password). They are usually produced by some large authentication scheme
#' (like the various OAuth 2.0 flows), but you are sometimes given then
#' directly.
#'
#' @seealso [RFC750](https://datatracker.ietf.org/doc/html/rfc6750)
#'   The OAuth 2.0 Authorization Framework: Bearer Token Usage
#' @inheritParams req_fetch
#' @param token A bearer token
#' @export
req_auth_bearer_token <- function(req, token) {
  check_request(req)
  check_string(token, "`token`")
  req_headers(req, Authorization = paste("Bearer", token))
}
