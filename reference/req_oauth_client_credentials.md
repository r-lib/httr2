# OAuth with client credentials

Authenticate using OAuth **client credentials flow**, as defined by
[Section 4.4 of RFC
6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.4). It is
used to allow the client to access resources that it controls directly,
not on behalf of an user.

Learn more about the overall OAuth authentication flow in
<https://httr2.r-lib.org/articles/oauth.html>.

## Usage

``` r
req_oauth_client_credentials(req, client, scope = NULL, token_params = list())

oauth_flow_client_credentials(client, scope = NULL, token_params = list())
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- client:

  An
  [`oauth_client()`](https://httr2.r-lib.org/reference/oauth_client.md).

- scope:

  Scopes to be requested from the resource owner.

- token_params:

  List containing additional parameters passed to the `token_url`.

## Value

`req_oauth_client_credentials()` returns a modified HTTP
[request](https://httr2.r-lib.org/reference/request.md) that will use
OAuth; `oauth_flow_client_credentials()` returns an
[oauth_token](https://httr2.r-lib.org/reference/oauth_token.md).

## See also

Other OAuth flows:
[`req_oauth_auth_code()`](https://httr2.r-lib.org/reference/req_oauth_auth_code.md),
[`req_oauth_bearer_jwt()`](https://httr2.r-lib.org/reference/req_oauth_bearer_jwt.md),
[`req_oauth_password()`](https://httr2.r-lib.org/reference/req_oauth_password.md),
[`req_oauth_refresh()`](https://httr2.r-lib.org/reference/req_oauth_refresh.md),
[`req_oauth_token_exchange()`](https://httr2.r-lib.org/reference/req_oauth_token_exchange.md)

## Examples

``` r
req_auth <- function(req) {
  req_oauth_client_credentials(
    req,
    client = oauth_client("example", "https://example.com/get_token")
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
