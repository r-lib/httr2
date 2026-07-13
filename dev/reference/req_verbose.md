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
#> -> User-Agent: httr2/1.2.3.9000 r-curl/7.1.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Sat, 11 Jul 2026 18:56:14 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6a5291ce-4ba0"
#> <- expires: Mon, 13 Jul 2026 17:32:01 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 4D54:3BEC8D:19BC483:1ABBC0C:6A551EB8
#> <- accept-ranges: bytes
#> <- date: Mon, 13 Jul 2026 17:26:02 GMT
#> <- via: 1.1 varnish
#> <- age: 20
#> <- x-served-by: cache-sjc10050-SJC
#> <- x-cache: HIT
#> <- x-cache-hits: 2
#> <- x-timer: S1783963562.484762,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 92a406ea82ab3adef9381c6e5ebfa8276ca18bac
#> <- content-length: 4831
#> <- 

# Or use one of the convenient shortcuts:
resp <- request("https://httr2.r-lib.org") |>
  req_perform(verbosity = 1)
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.2.3.9000 r-curl/7.1.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Sat, 11 Jul 2026 18:56:14 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6a5291ce-4ba0"
#> <- expires: Mon, 13 Jul 2026 17:32:01 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 4D54:3BEC8D:19BC483:1ABBC0C:6A551EB8
#> <- accept-ranges: bytes
#> <- date: Mon, 13 Jul 2026 17:26:02 GMT
#> <- via: 1.1 varnish
#> <- age: 20
#> <- x-served-by: cache-sjc10050-SJC
#> <- x-cache: HIT
#> <- x-cache-hits: 3
#> <- x-timer: S1783963562.497804,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 85d084dbc813701e09dcb9edd00dd4f79bc1f649
#> <- content-length: 4831
#> <- 
```
