#' OAuth authentication with a JWT
#'
#' @description
#' This uses [oauth_flow_jwt()] to generate an access token which is then
#' used to authenticate the request with [req_auth_bearer_token()].
#' The token is cached in memory.
#'
#' @export
#' @inheritParams req_fetch
#' @inheritParams oauth_flow_jwt
req_oauth_jwt <- function(req, app,
                          claims,
                          signature,
                          signature_params = list(),
                          scope = NULL,
                          token_params = list()
                          ) {

  params <- list(
    app = app,
    claims = claims,
    signature = signature,
    signature_params = signature_params,
    scope = scope,
    token_params = token_params
  )

  cache <- cache_mem(app, NULL)
  req_oauth(req, "oauth_flow_jwt", params, cache = cache)
}

#' OAuth flow: JWT
#'
#' This function implements the OAuth client credentials flow, as defined
#' by [rfc7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.1),
#' Section 2.1. It is often used for service accounts, accounts that are
#' used primarily in automated environments.
#'
#' @inheritParams oauth_flow_auth_code
#' @export
#' @family OAuth flows
#' @param claims A list of claims. If all elements of the claim set are static
#'   apart from `iat`, `nbf`, `exp`, or `jti`, provide a list and
#'   [jwt_claim()] will automatically fill in the dynamic components.
#'   If other components need to vary, you can instead provide a zero-argument
#'   callback function which should call `jwt_claim()`.
#' @param signature Function use to sign `claim_set`, e.g. [jwt_encode_sig()].
#' @param signature_params Additional arguments passed to `signature`, e.g.
#'   `key`, `size`, `header`.
oauth_flow_jwt <- function(app,
                           claims,
                           signature = "jwt_encode_sig",
                           signature_params = list(),
                           scope = NULL,
                           token_params = list()) {
  check_installed("jose")

  if (is_list(claims)) {
    claims <- exec("jwt_claim", !!!claims)
  } else if (is.function(claims)) {
    claims <- claims()
  } else {
    abort("`claims` must be result a list or function")
  }

  jwt <- exec(signature, claims, !!!signature_params)

  # https://datatracker.ietf.org/doc/html/rfc7523#section-2.1
  oauth_flow_access_token(app,
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion = jwt,
    scope = scope,
    !!!token_params
  )
}
