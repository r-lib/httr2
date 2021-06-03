# https://datatracker.ietf.org/doc/html/rfc6749#section-4.4
oauth_flow_client_credentials <- function(app,
                                          scope = NULL,
                                          token_params = list()
                                          ) {
  oauth_flow_check_app(app,
    flow = "client credentials",
    is_confidential = TRUE,
    endpoints = "token"
  )

  oauth_flow_access_token(app,
    grant_type = "client_credentials",
    scope = scope,
    !!!token_params
  )
}
