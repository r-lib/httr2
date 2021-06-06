#' Authenticate a request with an OAuth refresh token
#'
#' @description
#' This use [oauth_flow_refresh()] to generate an access token, then caches
#' it for use within the current session. This is primarily useful for testing:
#' you can manually perform another OAuth flow (e.g. by calling
#' [oauth_flow_auth_code()] or [oauth_flow_device()]), extract the refresh
#' token from the result, and then save in an environment variable for
#' future automated use.
#'
#' When requesting an access token, the server may also return a new refresh
#' token. If this happens, `oauth_flow_refresh()` will error, and you'll have
#' to create a new refresh token following the same procedure you did to get
#' the first token (so it's a good idea to document what you did the first time
#' because you might need to do it again).
#'
#' @inheritParams req_fetch
#' @inheritParams oauth_flow_refresh
req_oauth_refresh <- function(req,
                              app,
                              refresh_token = Sys.getenv("HTTR_REFRESH_TOKEN"),
                              scope = NULL,
                              token_params = list()) {

  params <- list(
    app = app,
    refresh_token = refresh_token,
    scope = scope,
    token_params = token_params
  )
  cache <- cache_mem(app, NULL)

  req_oauth(app, "oauth_flow_refresh", params, cache = cache)
}

#' OAuth flow: refresh token
#'
#' @description
#' This function generates an access token from a refresh token, following
#' the process described in
#' [rfc6749](https://datatracker.ietf.org/doc/html/rfc6749#section-6),
#' Section 6. Errors if the refresh returns a new refresh token, see
#' [req_oauth_refresh()] for details.
#'
#' @inheritParams oauth_flow_auth_code
#' @param refresh_token A refresh token. This is equivalent to a password
#'   so shouldn't be typed into the console or stored in a script. Instead,
#'   we recommend placing in an environment variable; the default behaviour
#'   is to look in `HTTR_REFRESH_TOKEN`.
#' @family OAuth flows
#' @export
oauth_flow_refresh <- function(app,
                               refresh_token = Sys.getenv("HTTR_REFRESH_TOKEN"),
                               scope = NULL,
                               token_params = list()) {
  oauth_flow_check_app(app,
    flow = "refresh",
    endpoints = "token"
  )

  token <- oauth_token_refresh(app,
    refresh_token = refresh_token,
    scope = scope,
    token_params = token_params
  )

  # Should generally do this automaitcaly, but in this workflow the token will
  # often be stored in an env var or similar
  if (token$refresh_token != token) {
    abort("Refresh token has changed! Please update stored value")
  }

  token
}

oauth_token_refresh <- function(app, refresh_token, scope = NULL, token_params = list()) {
  oauth_flow_access_token(app,
    grant_type = "refresh_token",
    refresh_token = refresh_token,
    scope = scope,
    !!!token_params
  )
}
