# Authenticate request with HTTP basic authentication

This sets the Authorization header. See details at
<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>.

## Usage

``` r
req_auth_basic(req, username, password = NULL)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- username:

  User name.

- password:

  Password. You should avoid entering the password directly when calling
  this function as it will be captured by `.Rhistory`. Instead, leave it
  unset and the default behaviour will prompt you for it interactively.

## Value

A modified HTTP [request](https://httr2.r-lib.org/reference/request.md).

## Examples

``` r
req <- request("http://example.com") |> req_auth_basic("hadley", "SECRET")
req
#> <httr2_request>
#> GET http://example.com
#> Headers:
#> * Authorization: <REDACTED>
#> Body: empty
req |> req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> authorization: <REDACTED>
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# httr2 does its best to redact the Authorization header so that you don't
# accidentally reveal confidential data. Use `redact_headers` to reveal it:
print(req, redact_headers = FALSE)
#> <httr2_request>
#> GET http://example.com
#> Headers:
#> * Authorization: "Basic aGFkbGV5OlNFQ1JFVA=="
#> Body: empty
req |> req_dry_run(redact_headers = FALSE)
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip, br, zstd
#> authorization: Basic aGFkbGV5OlNFQ1JFVA==
#> host: example.com
#> user-agent: httr2/1.2.2 r-curl/7.0.0 libcurl/8.5.0
#> 

# We do this because the authorization header is not encrypted and the
# so password can easily be discovered:
rawToChar(jsonlite::base64_dec("aGFkbGV5OlNFQ1JFVA=="))
#> [1] "hadley:SECRET"
```
