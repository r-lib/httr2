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

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
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

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## See also

[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
which exposes a limited subset of these options through the `verbosity`
argument and
[`with_verbosity()`](https://httr2.r-lib.org/dev/reference/with_verbosity.md)
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
#> -> User-Agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Fri, 19 Sep 2025 15:31:39 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"68cd775b-4ae0"
#> <- expires: Thu, 20 Nov 2025 09:14:41 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: E498:255CF0:800EA6:94E1AF:691ED9A9
#> <- accept-ranges: bytes
#> <- date: Thu, 20 Nov 2025 09:05:05 GMT
#> <- via: 1.1 varnish
#> <- age: 24
#> <- x-served-by: cache-iad-kcgs7200072-IAD
#> <- x-cache: HIT
#> <- x-cache-hits: 3
#> <- x-timer: S1763629506.576596,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 6aef9dd725629701477e40962807f69fd9f12af8
#> <- content-length: 4768
#> <- 

# Or use one of the convenient shortcuts:
resp <- request("https://httr2.r-lib.org") |>
  req_perform(verbosity = 1)
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Fri, 19 Sep 2025 15:31:39 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"68cd775b-4ae0"
#> <- expires: Thu, 20 Nov 2025 09:14:41 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: E498:255CF0:800EA6:94E1AF:691ED9A9
#> <- accept-ranges: bytes
#> <- date: Thu, 20 Nov 2025 09:05:05 GMT
#> <- via: 1.1 varnish
#> <- age: 24
#> <- x-served-by: cache-iad-kcgs7200072-IAD
#> <- x-cache: HIT
#> <- x-cache-hits: 4
#> <- x-timer: S1763629506.592879,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 4873da9fd1bfe1df992718c7a5e2b96d3eb76d0b
#> <- content-length: 4768
#> <- 
```
