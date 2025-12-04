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
#> <- last-modified: Thu, 04 Dec 2025 23:04:43 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6932138b-4ae0"
#> <- expires: Thu, 04 Dec 2025 23:15:45 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 54EC:F1088:1C60A02:1EEF1C9:693213C9
#> <- accept-ranges: bytes
#> <- date: Thu, 04 Dec 2025 23:06:17 GMT
#> <- via: 1.1 varnish
#> <- age: 0
#> <- x-served-by: cache-chi-kigq8000077-CHI
#> <- x-cache: HIT
#> <- x-cache-hits: 1
#> <- x-timer: S1764889577.493787,VS0,VE42
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 37bcdec291c3963d6e81b2c61290571385e4a1bf
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
#> <- last-modified: Thu, 04 Dec 2025 23:04:43 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6932138b-4ae0"
#> <- expires: Thu, 04 Dec 2025 23:15:45 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 54EC:F1088:1C60A02:1EEF1C9:693213C9
#> <- accept-ranges: bytes
#> <- date: Thu, 04 Dec 2025 23:06:17 GMT
#> <- via: 1.1 varnish
#> <- age: 0
#> <- x-served-by: cache-chi-kigq8000077-CHI
#> <- x-cache: HIT
#> <- x-cache-hits: 2
#> <- x-timer: S1764889578.558156,VS0,VE1
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 157dc958219b4222dec4fb560d30cebccab5f7a1
#> <- content-length: 4768
#> <- 
```
