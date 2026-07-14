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
#> -> User-Agent: httr2/1.3.0 r-curl/7.1.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Mon, 13 Jul 2026 19:57:01 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6a55430d-4ba0"
#> <- expires: Tue, 14 Jul 2026 08:41:24 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 130C:2308F9:2CFC12:2EC791:6A55F3DC
#> <- accept-ranges: bytes
#> <- date: Tue, 14 Jul 2026 13:25:48 GMT
#> <- via: 1.1 varnish
#> <- age: 19
#> <- x-served-by: cache-bur-kbur8200051-BUR
#> <- x-cache: HIT
#> <- x-cache-hits: 1
#> <- x-timer: S1784035549.820487,VS0,VE1
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 12092d4760b9290b76020044263d1c41bc50ff96
#> <- content-length: 4831
#> <- 

# Or use one of the convenient shortcuts:
resp <- request("https://httr2.r-lib.org") |>
  req_perform(verbosity = 1)
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.3.0 r-curl/7.1.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Mon, 13 Jul 2026 19:57:01 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6a55430d-4ba0"
#> <- expires: Tue, 14 Jul 2026 08:41:24 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 130C:2308F9:2CFC12:2EC791:6A55F3DC
#> <- accept-ranges: bytes
#> <- date: Tue, 14 Jul 2026 13:25:48 GMT
#> <- via: 1.1 varnish
#> <- age: 19
#> <- x-served-by: cache-bur-kbur8200051-BUR
#> <- x-cache: HIT
#> <- x-cache-hits: 2
#> <- x-timer: S1784035549.837536,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: dd1181772c5b86d685627c2c349454b6fd295a7c
#> <- content-length: 4831
#> <- 
```
