# https://datatracker.ietf.org/doc/html/rfc6749#section-4.2
oauth_flow_implicit <- function(app,
                                scope = NULL,
                                auth_params = list(),
                                hostname = "localhost",
                                port = 1410
) {
  oauth_flow_check_app(app,
    flow = "implicit",
    endpoints = "authorization"
  )
  check_installed("httpuv2")

  state <- nonce()
  redirect_url <- paste0("http://", hostname, ":", port)

  # Redirect user to authorisation url, and listen for result
  user_url <- oauth_flow_auth_code_url(app,
    response_type = "token",
    redirect_url = redirect_url,
    scope = scope,
    state = state,
    !!!auth_params
  )
  utils::browseURL(user_url)
  result <- oauth_flow_auth_code_listen(hostname, port)

  # TODO: check state
  # TODO: handle errors

  exec(new_token, !!!result$fragment)
}
