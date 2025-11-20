# OAuth token exchange

Authenticate by exchanging one security token for another, as defined by
[Section 2 of RFC
8693](https://datatracker.ietf.org/doc/html/rfc8693#section-2). It is
typically used for advanced authorization flows that involve
"delegation" or "impersonation" semantics, such as when a client
accesses a resource on behalf of another party, or when a client's
identity is federated from another provider.

Learn more about the overall OAuth authentication flow in
<https://httr2.r-lib.org/articles/oauth.html>.

## Usage

``` r
req_oauth_token_exchange(
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
)

oauth_flow_token_exchange(
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
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- client:

  An
  [`oauth_client()`](https://httr2.r-lib.org/dev/reference/oauth_client.md).

- subject_token:

  The security token to exchange. This is usually an OpenID Connect ID
  token or a SAML2 assertion.

- subject_token_type:

  A URI that describes the type of the security token. Usually one of
  the options in [Section 3 of RFC
  8693](https://datatracker.ietf.org/doc/html/rfc8693#section-3).

- resource:

  The URI that identifies the resource that the client is trying to
  access, if applicable.

- audience:

  The logical name that identifies the resource that the client is
  trying to access, if applicable. Usually one of `resource` or
  `audience` must be supplied.

- scope:

  Scopes to be requested from the resource owner.

- requested_token_type:

  An optional URI that describes the type of the security token being
  requested. Usually one of the options in [Section 3 of RFC
  8693](https://datatracker.ietf.org/doc/html/rfc8693#section-3).

- actor_token:

  An optional security token that represents the client, rather than the
  identity behind the subject token.

- actor_token_type:

  When `actor_token` is not `NULL`, this must be the URI that describes
  the type of the security token being requested. Usually one of the
  options in [Section 3 of RFC
  8693](https://datatracker.ietf.org/doc/html/rfc8693#section-3).

- token_params:

  List containing additional parameters passed to the `token_url`.

## Value

`req_oauth_token_exchange()` returns a modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md) that will
exchange one security token for another; `oauth_flow_token_exchange()`
returns the resulting
[oauth_token](https://httr2.r-lib.org/dev/reference/oauth_token.md)
directly.

## See also

Other OAuth flows:
[`req_oauth_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md),
[`req_oauth_bearer_jwt()`](https://httr2.r-lib.org/dev/reference/req_oauth_bearer_jwt.md),
[`req_oauth_client_credentials()`](https://httr2.r-lib.org/dev/reference/req_oauth_client_credentials.md),
[`req_oauth_password()`](https://httr2.r-lib.org/dev/reference/req_oauth_password.md),
[`req_oauth_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md)

## Examples

``` r
# List Google Cloud storage buckets using an OIDC token obtained
# from e.g. Microsoft Entra ID or Okta and federated to Google. (A real
# project ID and workforce pool would be required for this in practice.)
#
# See: https://cloud.google.com/iam/docs/workforce-obtaining-short-lived-credentials
oidc_token <- "an ID token from Okta"
request("https://storage.googleapis.com/storage/v1/b?project=123456") |>
  req_oauth_token_exchange(
    client = oauth_client("gcp", "https://sts.googleapis.com/v1/token"),
    subject_token = oidc_token,
    subject_token_type = "urn:ietf:params:oauth:token-type:id_token",
    scope = "https://www.googleapis.com/auth/cloud-platform",
    requested_token_type = "urn:ietf:params:oauth:token-type:access_token",
    audience = "//iam.googleapis.com/locations/global/workforcePools/123/providers/456",
    token_params = list(
      options = '{"userProject":"123456"}'
    )
  )
#> <httr2_request>
#> GET https://storage.googleapis.com/storage/v1/b?project=123456
#> Body: empty
#> Policies:
#> * auth_sign : <list>
#> * auth_oauth: TRUE
```
