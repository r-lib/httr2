# OAuth with authorization code

Authenticate using the OAuth **authorization code flow**, as defined by
[Section 4.1 of RFC
6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1).

This flow is the most commonly used OAuth flow where the user opens a
page in their browser, approves the access, and then returns to R. When
possible, it redirects the browser back to a temporary local webserver
to capture the authorization code. When this is not possible (e.g., when
running on a hosted platform like RStudio Server), provide a custom
`redirect_uri` and httr2 will prompt the user to enter the code
manually.

Learn more about the overall OAuth authentication flow in
<https://httr2.r-lib.org/articles/oauth.html>, and more about the
motivations behind this flow in
<https://stack-auth.com/blog/oauth-from-first-principles>.

## Usage

``` r
req_oauth_auth_code(
  req,
  client,
  auth_url,
  scope = NULL,
  pkce = TRUE,
  auth_params = list(),
  token_params = list(),
  redirect_uri = oauth_redirect_uri(),
  cache_disk = FALSE,
  cache_key = NULL
)

oauth_flow_auth_code(
  client,
  auth_url,
  scope = NULL,
  pkce = TRUE,
  auth_params = list(),
  token_params = list(),
  redirect_uri = oauth_redirect_uri()
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

- pkce:

  Use "Proof Key for Code Exchange"? This adds an extra layer of
  security and should always be used if supported by the server.

- auth_params:

  A list containing additional parameters passed to
  [`oauth_flow_auth_code_url()`](https://httr2.r-lib.org/reference/oauth_flow_auth_code_url.md).

- token_params:

  List containing additional parameters passed to the `token_url`.

- redirect_uri:

  URL to redirect back to after authorization is complete. Often this
  must be registered with the API in advance.

  httr2 supports three forms of redirect. Firstly, you can use a
  `localhost` url (the default), where httr2 will set up a temporary
  webserver to listen for the OAuth redirect. In this case, httr2 will
  automatically append a random port. If you need to set it to a fixed
  port because the API requires it, then specify it with (e.g.)
  `"http://localhost:1011"`. This technique works well when you are
  working on your own computer.

  Secondly, you can provide a URL to a website that uses Javascript to
  give the user a code to copy and paste back into the R session (see
  <https://tidyverse.org/google-callback/> and
  <https://github.com/r-lib/gargle/blob/main/inst/pseudo-oob/google-callback/index.html>
  for examples). This is less convenient (because it requires more user
  interaction) but also works in hosted environments like RStudio
  Server.

  Finally, hosted platforms might set the `HTTR2_OAUTH_REDIRECT_URL` and
  `HTTR2_OAUTH_CODE_SOURCE_URL` environment variables. In this case,
  httr2 will use `HTTR2_OAUTH_REDIRECT_URL` for redirects by default,
  and poll the `HTTR2_OAUTH_CODE_SOURCE_URL` endpoint with the state
  parameter until it receives a code in the response (or encounters an
  error). This delegates completion of the authorization flow to the
  hosted platform.

- cache_disk:

  Should the access token be cached on disk? This reduces the number of
  times that you need to re-authenticate at the cost of storing access
  credentials on disk.

  Learn more in <https://httr2.r-lib.org/articles/oauth.html>.

- cache_key:

  If you want to cache multiple tokens per app, use this key to
  disambiguate them.

## Value

`req_oauth_auth_code()` returns a modified HTTP
[request](https://httr2.r-lib.org/reference/request.md) that will use
OAuth; `oauth_flow_auth_code()` returns an
[oauth_token](https://httr2.r-lib.org/reference/oauth_token.md).

## Security considerations

The authorization code flow is used for both web applications and native
applications (which are equivalent to R packages). [RFC
8252](https://datatracker.ietf.org/doc/html/rfc8252) spells out
important considerations for native apps. Most importantly there's no
way for native apps to keep secrets from their users. This means that
the server should either not require a `client_secret` (i.e. it should
be a public client and not a confidential client) or ensure that
possession of the `client_secret` doesn't grant any significant
privileges.

Only modern APIs from major providers (like Azure and Google) explicitly
support native apps. However, in most cases, even for older APIs,
possessing the `client_secret` provides limited ability to perform
harmful actions. Therefore, our general principle is that it's
acceptable to include it in an R package, as long as it's mildly
obfuscated to protect against credential scraping attacks (which aim to
acquire large numbers of client secrets by scanning public sites like
GitHub). The goal is to ensure that obtaining your client credentials is
more work than just creating a new client.

## See also

[`oauth_flow_auth_code_url()`](https://httr2.r-lib.org/reference/oauth_flow_auth_code_url.md)
for the components necessary to write your own auth code flow, if the
API you are wrapping does not adhere closely to the standard.

Other OAuth flows:
[`req_oauth_bearer_jwt()`](https://httr2.r-lib.org/reference/req_oauth_bearer_jwt.md),
[`req_oauth_client_credentials()`](https://httr2.r-lib.org/reference/req_oauth_client_credentials.md),
[`req_oauth_password()`](https://httr2.r-lib.org/reference/req_oauth_password.md),
[`req_oauth_refresh()`](https://httr2.r-lib.org/reference/req_oauth_refresh.md),
[`req_oauth_token_exchange()`](https://httr2.r-lib.org/reference/req_oauth_token_exchange.md)

## Examples

``` r
req_auth_github <- function(req) {
  req_oauth_auth_code(
    req,
    client = example_github_client(),
    auth_url = "https://github.com/login/oauth/authorize"
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
