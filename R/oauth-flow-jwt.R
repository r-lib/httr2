#' OAuth authentication with a bearer JWT
#'
#' @description
#' This uses [oauth_flow_bearer_jwt()] to generate an access token which is then
#' used to authenticate the request with [req_auth_bearer_token()].
#' The token is cached in memory.
#'
#' @export
#' @inheritParams req_fetch
#' @inheritParams oauth_flow_bearer_jwt
req_oauth_bearer_jwt <- function(req, client,
                          claim,
                          signature = "jwt_encode_sig",
                          signature_params = list(),
                          scope = NULL,
                          token_params = list()
                          ) {

  params <- list(
    client = client,
    claim = claim,
    signature = signature,
    signature_params = signature_params,
    scope = scope,
    token_params = token_params
  )

  cache <- cache_mem(client, NULL)
  req_oauth(req, "oauth_flow_bearer_jwt", params, cache = cache)
}

#' OAuth flow: Bearer JWT
#'
#' This function uses a Bearer JWT as an authorization grant to get an access
#' token, as defined by [rfc7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.1),
#' Section 2.1. It is often used for service accounts, accounts that are
#' used primarily in automated environments.
#'
#' @inheritParams oauth_flow_auth_code
#' @export
#' @family OAuth flows
#' @param claim A list of claims. If all elements of the claim set are static
#'   apart from `iat`, `nbf`, `exp`, or `jti`, provide a list and
#'   [jwt_claim()] will automatically fill in the dynamic components.
#'   If other components need to vary, you can instead provide a zero-argument
#'   callback function which should call `jwt_claim()`.
#' @param signature Function use to sign `claim`, e.g. [jwt_encode_sig()].
#' @param signature_params Additional arguments passed to `signature`, e.g.
#'   `size`, `header`.
oauth_flow_bearer_jwt <- function(client,
                           claim,
                           signature = "jwt_encode_sig",
                           signature_params = list(),
                           scope = NULL,
                           token_params = list()) {
  check_installed("jose")
  if (is.null(client$key)) {
    abort("JWT flow requires `client` with a key")
  }

  if (is_list(claim)) {
    claim <- exec("jwt_claim", !!!claim)
  } else if (is.function(claim)) {
    claim <- claim()
  } else {
    abort("`claim` must be result a list or function")
  }

  jwt <- exec(signature, claim = claim, key = client$key, !!!signature_params)

  # https://datatracker.ietf.org/doc/html/rfc7523#section-2.1
  oauth_client_get_token(client,
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion = jwt,
    scope = scope,
    !!!token_params
  )
}
