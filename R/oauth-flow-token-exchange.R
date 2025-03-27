#' OAuth token exchange
#'
#' @description
#' Authenticate by exchanging one security token for another, as defined by
#' `r rfc(8693, 2)`. It is typically used for advanced authorization flows that
#' involve "delegation" or "impersonation" semantics, such as when a client
#' accesses a resource on behalf of another party, or when a client's identity
#' is federated from another provider.
#'
#' Learn more about the overall OAuth authentication flow in
#' <https://httr2.r-lib.org/articles/oauth.html>.
#'
#' @export
#' @family OAuth flows
#' @inheritParams req_perform
#' @inheritParams req_oauth_auth_code
#' @param subject_token The security token to exchange. This is usually an
#'   OpenID Connect ID token or a SAML2 assertion.
#' @param subject_token_type A URI that describes the type of the security
#'   token. Usually one of the options in `r rfc(8693, 3)`.
#' @param resource The URI that identifies the resource that the client is
#'   trying to access, if applicable.
#' @param audience The logical name that identifies the resource that the client
#'   is trying to access, if applicable. Usually one of `resource` or `audience`
#'   must be supplied.
#' @param requested_token_type An optional URI that describes the type of the
#'   security token being requested. Usually one of the options in
#'   `r rfc(8693, 3)`.
#' @param actor_token An optional security token that represents the client,
#'   rather than the identity behind the subject token.
#' @param actor_token_type When `actor_token` is not `NULL`, this must be the
#'   URI that describes the type of the security token being requested. Usually
#'   one of the options in `r rfc(8693, 3)`.
#' @returns `req_oauth_token_exchange()` returns a modified HTTP [request] that
#'   will exchange one security token for another; `oauth_flow_token_exchange()`
#'   returns the resulting [oauth_token] directly.
#'
#' @examples
#' # List Google Cloud storage buckets using an OIDC token obtained
#' # from e.g. Microsoft Entra ID or Okta and federated to Google. (A real
#' # project ID and workforce pool would be required for this in practice.)
#' #
#' # See: https://cloud.google.com/iam/docs/workforce-obtaining-short-lived-credentials
#' oidc_token <- "an ID token from Okta"
#' request("https://storage.googleapis.com/storage/v1/b?project=123456") |>
#'   req_oauth_token_exchange(
#'     client = oauth_client("gcp", "https://sts.googleapis.com/v1/token"),
#'     subject_token = oidc_token,
#'     subject_token_type = "urn:ietf:params:oauth:token-type:id_token",
#'     scope = "https://www.googleapis.com/auth/cloud-platform",
#'     requested_token_type = "urn:ietf:params:oauth:token-type:access_token",
#'     audience = "//iam.googleapis.com/locations/global/workforcePools/123/providers/456",
#'     token_params = list(
#'       options = '{"userProject":"123456"}'
#'     )
#'   )
req_oauth_token_exchange <- function(
  req,
  client,
  subject_token,
  subject_token_type,
  resource = NULL,
  audience = NULL,
  scope = NULL,
  requested_token_type = NULL,
  actor_token = NULL,
  actor_token_type = NULL,
  token_params = list()
) {
  params <- list(
    client = client,
    subject_token = subject_token,
    subject_token_type = subject_token_type,
    resource = resource,
    audience = audience,
    scope = scope,
    requested_token_type = requested_token_type,
    actor_token = actor_token,
    actor_token_type = actor_token_type,
    token_params = token_params
  )
  cache <- cache_mem(client, NULL)
  req_oauth(req, "oauth_flow_token_exchange", params, cache = cache)
}

#' @export
#' @rdname req_oauth_token_exchange
oauth_flow_token_exchange <- function(
  client,
  subject_token,
  subject_token_type,
  resource = NULL,
  audience = NULL,
  scope = NULL,
  requested_token_type = NULL,
  actor_token = NULL,
  actor_token_type = NULL,
  token_params = list()
) {
  oauth_client_get_token(
    client,
    grant_type = "urn:ietf:params:oauth:grant-type:token-exchange",
    subject_token = subject_token,
    subject_token_type = subject_token_type,
    resource = resource,
    audience = audience,
    scope = scope,
    requested_token_type = requested_token_type,
    actor_token = actor_token,
    actor_token_type = actor_token_type,
    !!!token_params
  )
}
