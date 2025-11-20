# Retrieve an OAuth token using the cache

This function wraps around a `oauth_flow_` function to retrieve a token
from the cache, or to generate and cache a token if needed. Use this for
manual token management that still takes advantage of httr2's caching
system. You should only need to use this function if you're passing the
token

## Usage

``` r
oauth_token_cached(
  client,
  flow,
  flow_params = list(),
  cache_disk = FALSE,
  cache_key = NULL,
  reauth = FALSE
)
```

## Arguments

- client:

  An
  [`oauth_client()`](https://httr2.r-lib.org/dev/reference/oauth_client.md).

- flow:

  An `oauth_flow_` function used to generate the access token.

- flow_params:

  Parameters for the flow. This should be a named list whose names match
  the argument names of `flow`.

- cache_disk:

  Should the access token be cached on disk? This reduces the number of
  times that you need to re-authenticate at the cost of storing access
  credentials on disk.

  Learn more in <https://httr2.r-lib.org/articles/oauth.html>.

- cache_key:

  If you want to cache multiple tokens per app, use this key to
  disambiguate them.

- reauth:

  Set to `TRUE` to force re-authentication via flow, regardless of
  whether or not token is expired.

## Examples

``` r
if (FALSE) { # \dontrun{
token <- oauth_token_cached(
  client = example_github_client(),
  flow = oauth_flow_auth_code,
  flow_params = list(
    auth_url = "https://github.com/login/oauth/authorize"
  ),
  cache_disk = TRUE
)
token
} # }
```
