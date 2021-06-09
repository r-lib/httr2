#' Authenticate request with HTTP basic authentication
#'
#' This sets the Authorization header. See details at
#' <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>.
#'
#' @inheritParams req_fetch
#' @param username User name.
#' @param password Password. You avoid entering the password directly when
#'   calling this function as it will be captured by `.Rhistory`. Instead,
#'   leave it unset and the default behaviour will prompt you for it
#'   interactively.
#' @export
#' @examples
#' req <- request("http://example.com") %>% req_auth_basic("hadley", "SECRET")
#' req
#' req %>% req_dry_run()
#'
#' # httr2 does its best to redact the Authorization header so that you don't
#' # accidentally confidential data. If you need to see exactly what's happening
#' # you can use redact = FALSE
#' print(req, redact = FALSE)
#' req %>% req_dry_run(redact = FALSE)
#'
#' # Note that the authorization header is not encrypted and the
#' # password can easily be restored:
#' rawToChar(jsonlite::base64_dec("aGFkbGV5IDogU0VDUkVU"))
#' # This means that you should be careful when sharing any code that
#' # reveals the Authorization header
req_auth_basic <- function(req, username, password = NULL) {
  check_request(req)
  check_string(username, "`username`")
  password <- check_password(password)

  username_password <- openssl::base64_encode(paste0(username, ":", password))
  req_headers(req, Authorization = paste0("Basic ", username_password))
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
