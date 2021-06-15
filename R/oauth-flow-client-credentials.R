#' OAuth authentication with client credentials
#'
#' @description
#' This uses [oauth_flow_client_credentials()] to generate an access token,
#' which is then used to authentication the request with [req_auth_bearer_token()].
#' The token is cached in memory.
#'
#' @export
#' @inheritParams req_fetch
#' @inheritParams oauth_flow_client_credentials
req_oauth_client_credentials <- function(req, client,
                                         scope = NULL,
                                         token_params = list()
                                         ) {

  params <- list(
    client = client,
    scope = scope,
    token_params = token_params
  )

  cache <- cache_mem(client, NULL)
  req_oauth(req, "oauth_flow_client_credentials", params, cache = cache)
}

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
oauth_flow_client_credentials <- function(client,
                                          scope = NULL,
                                          token_params = list()
                                          ) {
  oauth_flow_check("client credentials", client, is_confidential = TRUE)

  oauth_flow_access_token(client,
    grant_type = "client_credentials",
    scope = scope,
    !!!token_params
  )
}
