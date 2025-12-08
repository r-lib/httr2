# OAuth with username and password

This function implements the OAuth **resource owner password flow**, as
defined by [Section 4.3 of RFC
6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3). It
allows the user to supply their password once, exchanging it for an
access token that can be cached locally.

Learn more about the overall OAuth authentication flow in
<https://httr2.r-lib.org/articles/oauth.html>

## Usage

``` r
req_oauth_password(
  req,
  client,
  username,
  password = NULL,
  scope = NULL,
  token_params = list(),
  cache_disk = FALSE,
  cache_key = username
)

oauth_flow_password(
  client,
  username,
  password = NULL,
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

- username:

  User name.

- password:

  Password. You should avoid entering the password directly when calling
  this function as it will be captured by `.Rhistory`. Instead, leave it
  unset and the default behaviour will prompt you for it interactively.

- scope:

  Scopes to be requested from the resource owner.

- token_params:

  List containing additional parameters passed to the `token_url`.

- cache_disk:

  Should the access token be cached on disk? This reduces the number of
  times that you need to re-authenticate at the cost of storing access
  credentials on disk.

  Learn more in <https://httr2.r-lib.org/articles/oauth.html>.

- cache_key:

  If you want to cache multiple tokens per app, use this key to
  disambiguate them.

## Value

`req_oauth_password()` returns a modified HTTP
[request](https://httr2.r-lib.org/reference/request.md) that will use
OAuth; `oauth_flow_password()` returns an
[oauth_token](https://httr2.r-lib.org/reference/oauth_token.md).

## See also

Other OAuth flows:
[`req_oauth_auth_code()`](https://httr2.r-lib.org/reference/req_oauth_auth_code.md),
[`req_oauth_bearer_jwt()`](https://httr2.r-lib.org/reference/req_oauth_bearer_jwt.md),
[`req_oauth_client_credentials()`](https://httr2.r-lib.org/reference/req_oauth_client_credentials.md),
[`req_oauth_refresh()`](https://httr2.r-lib.org/reference/req_oauth_refresh.md),
[`req_oauth_token_exchange()`](https://httr2.r-lib.org/reference/req_oauth_token_exchange.md)

## Examples

``` r
req_auth <- function(req) {
  req_oauth_password(req,
    client = oauth_client("example", "https://example.com/get_token"),
    username = "username"
  )
}
if (interactive()) {
  request("https://example.com") |>
    req_auth()
}
```
