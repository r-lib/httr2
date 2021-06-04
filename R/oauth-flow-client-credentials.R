#' OAuth flow: client credentials
#'
#' This function implements the OAuth client credentials flow, as defined
#' by [rfc6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.4),
#' Section 4.4. It is used to allow the client to access resources that it
#' controls directly, not on behalf of an user.
#'
#' @inheritParams oauth_flow_auth_code
#' @export
#' @family OAuth flows
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
