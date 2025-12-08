# OAuth authentication

This is a low-level helper for automatically authenticating a request
with an OAuth flow, caching the access token and refreshing it where
possible. You should only need to use this function if you're
implementing your own OAuth flow.

## Usage

``` r
req_oauth(req, flow, flow_params, cache)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- flow:

  An `oauth_flow_` function used to generate the access token.

- flow_params:

  Parameters for the flow. This should be a named list whose names match
  the argument names of `flow`.

- cache:

  An object that controls how the token is cached. This should be a list
  containing three functions:

  - [`get()`](https://rdrr.io/r/base/get.html) retrieves the token from
    the cache, returning `NULL` if not cached yet.

  - `set()` saves the token to the cache.

  - `clear()` removes the token from the cache

## Value

An [oauth_token](https://httr2.r-lib.org/reference/oauth_token.md).
