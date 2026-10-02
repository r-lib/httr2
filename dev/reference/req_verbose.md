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
#> -> User-Agent: httr2/1.3.0.9000 r-curl/8.0.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- x-origin-cache: HIT
#> <- last-modified: Thu, 10 Sep 2026 14:59:01 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6aa2c5b5-4c24"
#> <- expires: Fri, 02 Oct 2026 21:29:02 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 3800:1C5DC6:7FA3E7:89B15E:6AC01FC4
#> <- x-github-edge-region: iad
#> <- accept-ranges: bytes
#> <- date: Fri, 02 Oct 2026 21:19:17 GMT
#> <- via: 1.1 varnish
#> <- age: 15
#> <- x-served-by: cache-dfw-kdfw8210127-DFW
#> <- x-cache: HIT
#> <- x-cache-hits: 1
#> <- x-timer: S1790975957.401224,VS0,VE2
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: d4728a55553fca13531b12379dc94087e4f989d3
#> <- content-length: 4860
#> <- 

# Or use one of the convenient shortcuts:
resp <- request("https://httr2.r-lib.org") |>
  req_perform(verbosity = 1)
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.3.0.9000 r-curl/8.0.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- x-origin-cache: HIT
#> <- last-modified: Thu, 10 Sep 2026 14:59:01 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6aa2c5b5-4c24"
#> <- expires: Fri, 02 Oct 2026 21:29:02 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 3800:1C5DC6:7FA3E7:89B15E:6AC01FC4
#> <- x-github-edge-region: iad
#> <- accept-ranges: bytes
#> <- date: Fri, 02 Oct 2026 21:19:17 GMT
#> <- via: 1.1 varnish
#> <- age: 15
#> <- x-served-by: cache-dfw-kdfw8210127-DFW
#> <- x-cache: HIT
#> <- x-cache-hits: 2
#> <- x-timer: S1790975957.430177,VS0,VE1
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: aec2efb8a09e4fc01d1126d8798b6a0413d750c9
#> <- content-length: 4860
#> <- 
```
