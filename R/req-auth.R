#' Authenticate request with HTTP basic authentication
#'
#' This sets the Authorization header. See details at
#' <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>.
#'
#' @inheritParams req_perform
#' @param username User name.
#' @param password Password. You avoid entering the password directly when
#'   calling this function as it will be captured by `.Rhistory`. Instead,
#'   leave it unset and the default behaviour will prompt you for it
#'   interactively.
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' req <- request("http://example.com") |> req_auth_basic("hadley", "SECRET")
#' req
#' req |> req_dry_run()
#'
#' # httr2 does its best to redact the Authorization header so that you don't
#' # accidentally reveal confidential data. Use `redact_headers` to reveal it:
#' print(req, redact_headers = FALSE)
#' req |> req_dry_run(redact_headers = FALSE)
#'
#' # We do this because the authorization header is not encrypted and the
#' # so password can easily be discovered:
#' rawToChar(jsonlite::base64_dec("aGFkbGV5OlNFQ1JFVA=="))
req_auth_basic <- function(req, username, password = NULL) {
  check_request(req)
  check_string(username)
  password <- check_password(password)

  username_password <- openssl::base64_encode(paste0(username, ":", password))
  req_headers(req, Authorization = paste0("Basic ", username_password), .redact = "Authorization")
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
#' @inheritParams req_perform
#' @param token A bearer token
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' req <- request("http://example.com") |> req_auth_bearer_token("sdaljsdf093lkfs")
#' req
#'
#' # httr2 does its best to redact the Authorization header so that you don't
#' # accidentally reveal confidential data. Use `redact_headers` to reveal it:
#' print(req, redact_headers = FALSE)
req_auth_bearer_token <- function(req, token) {
  check_request(req)
  check_string(token)
  req_headers(req, Authorization = paste("Bearer", token), .redact = "Authorization")
}
