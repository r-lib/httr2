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
#> -> User-Agent: httr2/1.2.2.9000 r-curl/7.0.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Mon, 08 Dec 2025 15:02:17 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6936e879-4b79"
#> <- expires: Mon, 08 Dec 2025 15:13:22 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 4476:135A:7259CB:768AA7:6936E8B9
#> <- accept-ranges: bytes
#> <- date: Mon, 08 Dec 2025 15:03:37 GMT
#> <- via: 1.1 varnish
#> <- age: 16
#> <- x-served-by: cache-pao-kpao1770022-PAO
#> <- x-cache: HIT
#> <- x-cache-hits: 1
#> <- x-timer: S1765206218.827020,VS0,VE1
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: d98c752bec8e6c1973f82f6bee3cbab24f64d7e9
#> <- content-length: 4833
#> <- 

# Or use one of the convenient shortcuts:
resp <- request("https://httr2.r-lib.org") |>
  req_perform(verbosity = 1)
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.2.2.9000 r-curl/7.0.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Mon, 08 Dec 2025 15:02:17 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6936e879-4b79"
#> <- expires: Mon, 08 Dec 2025 15:13:22 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 4476:135A:7259CB:768AA7:6936E8B9
#> <- accept-ranges: bytes
#> <- date: Mon, 08 Dec 2025 15:03:37 GMT
#> <- via: 1.1 varnish
#> <- age: 16
#> <- x-served-by: cache-pao-kpao1770022-PAO
#> <- x-cache: HIT
#> <- x-cache-hits: 2
#> <- x-timer: S1765206218.844334,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 8deb066b01c399a5c4141bf4fe82d8695eaab7e5
#> <- content-length: 4833
#> <- 
```
