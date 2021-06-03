# https://datatracker.ietf.org/doc/html/rfc6749#section-4.3
oauth_flow_password <- function(app,
                                username,
                                password = NULL,
                                scope = NULL,
                                token_params = list()
) {
  oauth_flow_check_app(app,
    flow = "resource owner password credentials",
    endpoints = "token"
  )
  check_string(username, "`username`")
  if (is.null(password)) {
    check_installed("askpass")
    password <- askpass::askpass()
  }
  check_string(password, "`password`")

  oauth_flow_access_token(app,
    grant_type = "password",
    username = username,
    password = password,
    scope = scope,
    !!!token_params
  )
}
