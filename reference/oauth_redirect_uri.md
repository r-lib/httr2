# Default redirect url for OAuth

The default redirect uri used by
[`req_oauth_auth_code()`](https://httr2.r-lib.org/reference/req_oauth_auth_code.md).
Defaults to `http://localhost` unless the `HTTR2_OAUTH_REDIRECT_URL`
envvar is set.

## Usage

``` r
oauth_redirect_uri()
```
