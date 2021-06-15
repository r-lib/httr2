#' OAuth authentication with username and password
#'
#' @description
#' This uses [oauth_flow_password()] to generate an access token, which is
#' then used to authentication the request with [req_auth_bearer_token()].
#' The token, not the password is automatically cached (either in memory
#' or on disk); the password is used once to get the token and is then
#' discarded.
#'
#' @export
#' @inheritParams oauth_flow_password
#' @inheritParams req_oauth_auth_code
req_oauth_password <- function(req, client,
                               username,
                               password = NULL,
                               cache_disk = FALSE,
                               scope = NULL,
                               token_params = list()) {

  password <- check_password(password)
  params <- list(
    client = client,
    username = username,
    password = password,
    scope = scope,
    token_params = token_params
  )
  cache <- cache_choose(client, cache_disk = cache_disk, cache_key = username)
  req_oauth(req, "oauth_flow_password", params, cache = cache)
}

#' OAuth flow: user password
#'
#' This function implements the OAuth resource owner password flow, as defined
#' by [rfc6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3),
#' Section 4.3. It allows the user to supply their password once, exchanging
#' it for an access token that can be cached locally.
#'
#' @inheritParams oauth_flow_auth_code
#' @inheritParams req_auth_basic
#' @export
#' @family OAuth flows
oauth_flow_password <- function(client,
                                username,
                                password = NULL,
                                scope = NULL,
                                token_params = list()
) {
  oauth_flow_check("resource owner password credentials", client,
    interactive = is.null(password)
  )
  check_string(username, "`username`")
  password <- check_password(password)

  oauth_client_token(client,
    grant_type = "password",
    username = username,
    password = password,
    scope = scope,
    !!!token_params
  )
}

check_password <- function(password) {
  if (is.null(password)) {
    check_installed("askpass")
    password <- askpass::askpass()
  }
  check_string(password, "`password`")
  password
}
