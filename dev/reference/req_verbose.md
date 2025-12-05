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
#> <- last-modified: Fri, 05 Dec 2025 16:50:44 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"69330d64-4ae0"
#> <- expires: Fri, 05 Dec 2025 17:01:29 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 7A9B:294EAB:3578D8:38B150:69330D91
#> <- accept-ranges: bytes
#> <- date: Fri, 05 Dec 2025 16:52:20 GMT
#> <- via: 1.1 varnish
#> <- age: 16
#> <- x-served-by: cache-chi-kigq8000178-CHI
#> <- x-cache: HIT
#> <- x-cache-hits: 2
#> <- x-timer: S1764953541.980189,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 1fb2406ccc6550ff0a5aba5a11eed2e6af417857
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
#> <- last-modified: Fri, 05 Dec 2025 16:50:44 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"69330d64-4ae0"
#> <- expires: Fri, 05 Dec 2025 17:01:29 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 7A9B:294EAB:3578D8:38B150:69330D91
#> <- accept-ranges: bytes
#> <- date: Fri, 05 Dec 2025 16:52:20 GMT
#> <- via: 1.1 varnish
#> <- age: 16
#> <- x-served-by: cache-chi-kigq8000178-CHI
#> <- x-cache: HIT
#> <- x-cache-hits: 3
#> <- x-timer: S1764953541.997758,VS0,VE1
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 53953111d44295e38a3b733feb2afbff49840118
#> <- content-length: 4768
#> <- 
```
