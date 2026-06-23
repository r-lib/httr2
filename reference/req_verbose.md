# Show extra output when request is performed

`req_verbose()` uses the following prefixes to distinguish between
different components of the HTTP requests and responses:

- `* ` informative curl messages

- `->` request headers

- `>>` request body

- `<-` response headers

- `<<` response body

## Usage

``` r
req_verbose(
  req,
  header_req = TRUE,
  header_resp = TRUE,
  body_req = FALSE,
  body_resp = FALSE,
  info = FALSE,
  redact_headers = TRUE
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- header_req, header_resp:

  Show request/response headers?

- body_req, body_resp:

  Should request/response bodies? When the response body is compressed,
  this will show the number of bytes received in each "chunk".

- info:

  Show informational text from curl? This is mainly useful for debugging
  https and auth problems, so is disabled by default.

- redact_headers:

  Redact confidential data in the headers? Currently redacts the
  contents of the Authorization header to prevent you from accidentally
  leaking credentials when debugging/reprexing.

## Value

A modified HTTP [request](https://httr2.r-lib.org/reference/request.md).

## See also

[`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md)
which exposes a limited subset of these options through the `verbosity`
argument and
[`with_verbosity()`](https://httr2.r-lib.org/reference/with_verbosity.md)
which allows you to control the verbosity of requests deeper within the
call stack.

## Examples

``` r
# Use `req_verbose()` to see the headers that are sent back and forth when
# making a request
resp <- request("https://httr2.r-lib.org") |>
  req_verbose() |>
  req_perform()
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.2.3 r-curl/7.1.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Mon, 22 Jun 2026 22:14:26 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6a39b3c2-4b79"
#> <- expires: Tue, 23 Jun 2026 10:12:12 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: E5FC:2FEF0E:3FA85A:41E0F1:6A3A59A3
#> <- accept-ranges: bytes
#> <- date: Tue, 23 Jun 2026 12:27:53 GMT
#> <- via: 1.1 varnish
#> <- age: 16
#> <- x-served-by: cache-pao-kpao1770072-PAO
#> <- x-cache: HIT
#> <- x-cache-hits: 1
#> <- x-timer: S1782217673.105105,VS0,VE1
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 026bdc505ac0e21d950ea3ea29241d0e194e75ff
#> <- content-length: 4833
#> <- 

# Or use one of the convenient shortcuts:
resp <- request("https://httr2.r-lib.org") |>
  req_perform(verbosity = 1)
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.2.3 r-curl/7.1.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Mon, 22 Jun 2026 22:14:26 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6a39b3c2-4b79"
#> <- expires: Tue, 23 Jun 2026 10:12:12 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: E5FC:2FEF0E:3FA85A:41E0F1:6A3A59A3
#> <- accept-ranges: bytes
#> <- date: Tue, 23 Jun 2026 12:27:53 GMT
#> <- via: 1.1 varnish
#> <- age: 16
#> <- x-served-by: cache-pao-kpao1770072-PAO
#> <- x-cache: HIT
#> <- x-cache-hits: 2
#> <- x-timer: S1782217673.118188,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 22248224f9acbbb033aa119393145ee88784085c
#> <- content-length: 4833
#> <- 
```
