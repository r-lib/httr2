# OAuth with device flow

Authenticate using the OAuth **device flow**, as defined by [RFC
8628](https://datatracker.ietf.org/doc/html/rfc8628). It's designed for
devices that don't have access to a web browser (if you've ever
authenticated an app on your TV, this is probably the flow you've used),
but it also works well from within R.

Learn more about the overall OAuth authentication flow in
<https://httr2.r-lib.org/articles/oauth.html>.

## Usage

``` r
req_oauth_device(
  req,
  client,
  auth_url,
  scope = NULL,
  open_browser = is_interactive(),
  auth_params = list(),
  token_params = list(),
  cache_disk = FALSE,
  cache_key = NULL
)

oauth_flow_device(
  client,
  auth_url,
  pkce = FALSE,
  scope = NULL,
  open_browser = is_interactive(),
  auth_params = list(),
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

- auth_url:

  Authorization url; you'll need to discover this by reading the
  documentation.

- scope:

  Scopes to be requested from the resource owner.

- open_browser:

  If `TRUE` (the default in interactive sessions), the device
  verification URL will be opened in the user's browser. If `FALSE`, the
  URL is printed to the console and the user must open it themselves.

- auth_params:

  A list containing additional parameters passed to
  [`oauth_flow_auth_code_url()`](https://httr2.r-lib.org/reference/oauth_flow_auth_code_url.md).

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

- pkce:

  Use "Proof Key for Code Exchange"? This adds an extra layer of
  security and should always be used if supported by the server.

## Value

`req_oauth_device()` returns a modified HTTP
[request](https://httr2.r-lib.org/reference/request.md) that will use
OAuth; `oauth_flow_device()` returns an
[oauth_token](https://httr2.r-lib.org/reference/oauth_token.md).

## Examples

``` r
req_auth_github <- function(req) {
  req_oauth_device(
    req,
    client = example_github_client(),
    auth_url = "https://github.com/login/device/code"
  )
}

request("https://api.github.com/user") |>
  req_auth_github()
#> <httr2_request>
#> GET https://api.github.com/user
#> Body: empty
#> Policies:
#> * auth_sign : <list>
#> * auth_oauth: TRUE
```
