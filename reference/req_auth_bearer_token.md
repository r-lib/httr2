# Authenticate request with bearer token

A bearer token gives the bearer access to confidential resources (so you
should keep them secure like you would with a user name and password).
They are usually produced by some large authentication scheme (like the
various OAuth 2.0 flows), but you are sometimes given then directly.

## Usage

``` r
req_auth_bearer_token(req, token)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- token:

  A bearer token

## Value

A modified HTTP [request](https://httr2.r-lib.org/reference/request.md).

## See also

See [RFC 6750](https://datatracker.ietf.org/doc/html/rfc6750) for more
details about bearer token usage with OAuth 2.0.

## Examples

``` r
req <- request("http://example.com") |> req_auth_bearer_token("sdaljsdf093lkfs")
req
#> <httr2_request>
#> GET http://example.com
#> Headers:
#> * Authorization: <REDACTED>
#> Body: empty

# httr2 does its best to redact the Authorization header so that you don't
# accidentally reveal confidential data. Use `redact_headers` to reveal it:
print(req, redact_headers = FALSE)
#> <httr2_request>
#> GET http://example.com
#> Headers:
#> * Authorization: "Bearer sdaljsdf093lkfs"
#> Body: empty
```
