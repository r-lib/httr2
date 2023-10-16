#' OAuth with client credentials
#'
#' @description
#' Authenticate using OAuth **client credentials flow**, as defined by
#' `r rfc(6749, 4.4)`. It is used to allow the client to access resources that
#' it controls directly, not on behalf of an user.
#'
#' Learn more about the overall OAuth authentication flow in `vignette("oauth")`.
#'
#' @export
#' @family OAuth flows
#' @inheritParams req_perform
#' @inheritParams req_oauth_auth_code
#' @returns `req_oauth_client_credentials()` returns a modified HTTP [request] that will
#'   use OAuth; `oauth_flow_client_credentials()` returns an [oauth_token].
#' @examples
#' req_auth <- function(req) {
#'   req_oauth_client_credentials(
#'     req,
#'     client = oauth_client("example", "https://example.com/get_token")
#'   )
#' }
#'
#' request("https://example.com") |>
#'   req_auth()
req_oauth_client_credentials <- function(req,
                                         client,
                                         scope = NULL,
                                         token_params = list()) {

  params <- list(
    client = client,
    scope = scope,
    token_params = token_params
  )

  cache <- cache_mem(client, NULL)
  req_oauth(req, "oauth_flow_client_credentials", params, cache = cache)
}

#' @export
#' @rdname req_oauth_client_credentials
oauth_flow_client_credentials <- function(client,
                                          scope = NULL,
                                          token_params = list()) {
  oauth_flow_check("client credentials", client, is_confidential = TRUE)

  oauth_client_get_token(client,
    grant_type = "client_credentials",
    scope = scope,
    !!!token_params
  )
}
