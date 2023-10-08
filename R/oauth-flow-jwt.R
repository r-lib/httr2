#' OAuth with a bearer JWT (JSON web token)
#'
#' @description
#' Authenticate using a **Bearer JWT** (JSON web token) as an authorization
#' grant to get an access token, as defined by `r rfc(7523, 2.1)`.
#' It is often used for service accounts, accounts that are used primarily in
#' automated environments.
#'
#' Learn more about the overall flow in `vignette("oauth")`.
#'
#' @export
#' @family OAuth flows
#' @inheritParams req_perform
#' @inheritParams req_oauth_auth_code
#' @param claim A list of claims. If all elements of the claim set are static
#'   apart from `iat`, `nbf`, `exp`, or `jti`, provide a list and
#'   [jwt_claim()] will automatically fill in the dynamic components.
#'   If other components need to vary, you can instead provide a zero-argument
#'   callback function which should call `jwt_claim()`.
#' @param signature Function use to sign `claim`, e.g. [jwt_encode_sig()].
#' @param signature_params Additional arguments passed to `signature`, e.g.
#'   `size`, `header`.
#' @returns `req_oauth_bearer_jwt()` returns a modified HTTP [request] that will
#'   use OAuth; `oauth_flow_bearer_jwt()` returns an [oauth_token].
#' @examples
#' req_auth <- function(req) {
#'   req_oauth_bearer_jwt(
#'     req,
#'     client = oauth_client("example", "https://example.com/get_token"),
#'     claim = jwt_claim()
#'   )
#' }
#'
#' request("https://example.com") %>%
#'  req_auth()
req_oauth_bearer_jwt <- function(req,
                                 client,
                                 claim,
                                 signature = "jwt_encode_sig",
                                 signature_params = list(),
                                 scope = NULL,
                                 token_params = list()) {

  params <- list(
    client = client,
    claim = claim,
    signature = signature,
    signature_params = signature_params,
    scope = scope,
    token_params = token_params
  )

  cache <- cache_mem(client, claim)
  req_oauth(req, "oauth_flow_bearer_jwt", params, cache = cache)
}

#' @export
#' @rdname req_oauth_bearer_jwt
oauth_flow_bearer_jwt <- function(client,
                                  claim,
                                  signature = "jwt_encode_sig",
                                  signature_params = list(),
                                  scope = NULL,
                                  token_params = list()) {
  check_installed("jose")
  if (is.null(client$key)) {
    cli::cli_abort("JWT flow requires {.arg client} with a key.")
  }

  if (is_list(claim)) {
    claim <- exec("jwt_claim", !!!claim)
  } else if (is.function(claim)) {
    claim <- claim()
  } else {
    cli::cli_abort("{.arg claim} must be a list or function.")
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
