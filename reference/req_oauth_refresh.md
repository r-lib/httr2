# OAuth with a refresh token

Authenticate using a **refresh token**, following the process described
in [Section 6 of RFC
6749](https://datatracker.ietf.org/doc/html/rfc6749#section-6).

This technique is primarily useful for testing: you can manually
retrieve a OAuth token using another OAuth flow (e.g. with
[`oauth_flow_auth_code()`](https://httr2.r-lib.org/reference/req_oauth_auth_code.md)),
extract the refresh token from the result, and then save in an
environment variable for use in automated tests.

When requesting an access token, the server may also return a new
refresh token. If this happens, `oauth_flow_refresh()` will warn, and
you'll have retrieve a new update refresh token and update the stored
value. If you find this happening a lot, it's a sign that you should be
using a different flow in your automated tests.

Learn more about the overall OAuth authentication flow in
<https://httr2.r-lib.org/articles/oauth.html>.

## Usage

``` r
req_oauth_refresh(
  req,
  client,
  refresh_token = Sys.getenv("HTTR2_REFRESH_TOKEN"),
  scope = NULL,
  token_params = list()
)

oauth_flow_refresh(
  client,
  refresh_token = Sys.getenv("HTTR2_REFRESH_TOKEN"),
  scope = NULL,
  token_params = list()
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- client:

  An
  [`oauth_client()`](https://httr2.r-lib.org/reference/oauth_client.md).

- refresh_token:

  A refresh token. This is equivalent to a password so shouldn't be
  typed into the console or stored in a script. Instead, we recommend
  placing in an environment variable; the default behaviour is to look
  in `HTTR2_REFRESH_TOKEN`.

- scope:

  Scopes to be requested from the resource owner.

- token_params:

  List containing additional parameters passed to the `token_url`.

## Value

`req_oauth_refresh()` returns a modified HTTP
[request](https://httr2.r-lib.org/reference/request.md) that will use
OAuth; `oauth_flow_refresh()` returns an
[oauth_token](https://httr2.r-lib.org/reference/oauth_token.md).

## See also

Other OAuth flows:
[`req_oauth_auth_code()`](https://httr2.r-lib.org/reference/req_oauth_auth_code.md),
[`req_oauth_bearer_jwt()`](https://httr2.r-lib.org/reference/req_oauth_bearer_jwt.md),
[`req_oauth_client_credentials()`](https://httr2.r-lib.org/reference/req_oauth_client_credentials.md),
[`req_oauth_password()`](https://httr2.r-lib.org/reference/req_oauth_password.md),
[`req_oauth_token_exchange()`](https://httr2.r-lib.org/reference/req_oauth_token_exchange.md)

## Examples

``` r
client <- oauth_client("example", "https://example.com/get_token")
req <- request("https://example.com")
req |> req_oauth_refresh(client)
#> <httr2_request>
#> GET https://example.com
#> Body: empty
#> Policies:
#> * auth_sign : <list>
#> * auth_oauth: TRUE
```
