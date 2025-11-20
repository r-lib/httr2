# OAuth with a bearer JWT (JSON web token)

Authenticate using a **Bearer JWT** (JSON web token) as an authorization
grant to get an access token, as defined by [Section 2.1 of RFC
7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.1). It is
often used for service accounts, accounts that are used primarily in
automated environments.

Learn more about the overall OAuth authentication flow in
<https://httr2.r-lib.org/articles/oauth.html>.

## Usage

``` r
req_oauth_bearer_jwt(
  req,
  client,
  claim,
  signature = "jwt_encode_sig",
  signature_params = list(),
  scope = NULL,
  token_params = list()
)

oauth_flow_bearer_jwt(
  client,
  claim,
  signature = "jwt_encode_sig",
  signature_params = list(),
  scope = NULL,
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

- claim:

  A list of claims. If all elements of the claim set are static apart
  from `iat`, `nbf`, `exp`, or `jti`, provide a list and
  [`jwt_claim()`](https://httr2.r-lib.org/dev/reference/jwt_claim.md)
  will automatically fill in the dynamic components. If other components
  need to vary, you can instead provide a zero-argument callback
  function which should call
  [`jwt_claim()`](https://httr2.r-lib.org/dev/reference/jwt_claim.md).

- signature:

  Function use to sign `claim`, e.g.
  [`jwt_encode_sig()`](https://httr2.r-lib.org/dev/reference/jwt_claim.md).

- signature_params:

  Additional arguments passed to `signature`, e.g. `size`, `header`.

- scope:

  Scopes to be requested from the resource owner.

- token_params:

  List containing additional parameters passed to the `token_url`.

## Value

`req_oauth_bearer_jwt()` returns a modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md) that will
use OAuth; `oauth_flow_bearer_jwt()` returns an
[oauth_token](https://httr2.r-lib.org/dev/reference/oauth_token.md).

## See also

Other OAuth flows:
[`req_oauth_auth_code()`](https://httr2.r-lib.org/dev/reference/req_oauth_auth_code.md),
[`req_oauth_client_credentials()`](https://httr2.r-lib.org/dev/reference/req_oauth_client_credentials.md),
[`req_oauth_password()`](https://httr2.r-lib.org/dev/reference/req_oauth_password.md),
[`req_oauth_refresh()`](https://httr2.r-lib.org/dev/reference/req_oauth_refresh.md),
[`req_oauth_token_exchange()`](https://httr2.r-lib.org/dev/reference/req_oauth_token_exchange.md)

## Examples

``` r
req_auth <- function(req) {
  req_oauth_bearer_jwt(
    req,
    client = oauth_client("example", "https://example.com/get_token"),
    claim = jwt_claim()
  )
}

request("https://example.com") |>
 req_auth()
#> <httr2_request>
#> GET https://example.com
#> Body: empty
#> Policies:
#> * auth_sign : <list>
#> * auth_oauth: TRUE
```
