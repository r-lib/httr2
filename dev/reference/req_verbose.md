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

  Show request/response bodies? When the response body is compressed,
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
#> -> User-Agent: httr2/1.3.0.9000 r-curl/8.1.0 libcurl/8.18.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Thu, 05 Nov 2026 16:46:51 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6aecb2fb-4c24"
#> <- expires: Sat, 07 Nov 2026 16:53:30 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 2A8A:4D6A:1033045:11AEA7B:6AEF5531
#> <- x-github-edge-region: iad
#> <- accept-ranges: bytes
#> <- date: Sat, 07 Nov 2026 17:09:49 GMT
#> <- via: 1.1 varnish
#> <- age: 16
#> <- x-served-by: cache-iad-kcgs7200146-IAD
#> <- x-cache: HIT
#> <- x-cache-hits: 1
#> <- x-timer: S1794071390.952061,VS0,VE25
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 1d573a95ae9b4ce4ef4a6295f283b7049464aac9
#> <- content-length: 4860
#> <- 

# Or use one of the convenient shortcuts:
resp <- request("https://httr2.r-lib.org") |>
  req_perform(verbosity = 1)
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.3.0.9000 r-curl/8.1.0 libcurl/8.18.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Thu, 05 Nov 2026 16:46:51 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6aecb2fb-4c24"
#> <- expires: Sat, 07 Nov 2026 16:53:30 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 2A8A:4D6A:1033045:11AEA7B:6AEF5531
#> <- x-github-edge-region: iad
#> <- accept-ranges: bytes
#> <- date: Sat, 07 Nov 2026 17:09:50 GMT
#> <- via: 1.1 varnish
#> <- age: 16
#> <- x-served-by: cache-iad-kcgs7200146-IAD
#> <- x-cache: HIT
#> <- x-cache-hits: 2
#> <- x-timer: S1794071390.001795,VS0,VE4
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 2b6f1d0987ff2c97f8a4f01f51f12eae2574655c
#> <- content-length: 4860
#> <- 
```
