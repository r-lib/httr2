# Create an OAuth token

Creates a S3 object of class `<httr2_token>` representing an OAuth token
returned from the access token endpoint.

## Usage

``` r
oauth_token(
  access_token,
  token_type = "bearer",
  expires_in = NULL,
  refresh_token = NULL,
  ...,
  .date = Sys.time()
)
```

## Arguments

- access_token:

  The access token used to authenticate request

- token_type:

  Type of token; only `"bearer"` is currently supported.

- expires_in:

  Number of seconds until token expires.

- refresh_token:

  Optional refresh token; if supplied, this can be used to cheaply get a
  new access token when this one expires.

- ...:

  Additional components returned by the endpoint

- .date:

  Date the request was made; used to convert the relative `expires_in`
  to an absolute `expires_at`.

## Value

An OAuth token: an S3 list with class `httr2_token`.

## See also

[`oauth_token_cached()`](https://httr2.r-lib.org/dev/reference/oauth_token_cached.md)
to use the token cache with a specified OAuth flow.

## Examples

``` r
oauth_token("abcdef")
#> <httr2_token>
#> * token_type  : "bearer"
#> * access_token: <REDACTED>
oauth_token("abcdef", expires_in = 3600)
#> <httr2_token>
#> * token_type  : "bearer"
#> * access_token: <REDACTED>
#> * expires_at  : "2026-01-14 20:12:27"
oauth_token("abcdef", refresh_token = "ghijkl")
#> <httr2_token>
#> * token_type   : "bearer"
#> * access_token : <REDACTED>
#> * refresh_token: <REDACTED>
```
