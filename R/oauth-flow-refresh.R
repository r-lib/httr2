oauth_flow_refresh <- function(app,
                               refresh_token,
                               scope = NULL,
                               token_params = list()) {
  oauth_flow_check_app(app,
    flow = "refresh",
    endpoints = "token"
  )

  token <- oauth_flow_access_token(app,
    grant_type = "refresh_token",
    refresh_token = refresh_token,
    scope = scope,
    !!!token_params
  )

  # Should generally do this automaitcaly, but in this workflow the token will
  # often be stored in an env var or similar
  if (token$refresh_token != token) {
    warn("Refresh token has changed! Please update stored value")
  }

  token
}
