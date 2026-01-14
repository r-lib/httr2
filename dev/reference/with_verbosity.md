# Temporarily set verbosity for all requests

`with_verbosity()` and `local_verbosity()` are useful for debugging
httr2 code buried deep inside another package, because they allow you to
change the verbosity even when you don't have access to the request.

Both functions work by temporarily setting the `httr2_verbosity` option.
You can also control verbosity by setting the `HTTR2_VERBOSITY`
environment variable. This has lower precedence than the option, but can
be more easily changed outside of R.

## Usage

``` r
with_verbosity(code, verbosity = 1)

local_verbosity(verbosity, env = caller_env())
```

## Arguments

- code:

  Code to execture

- verbosity:

  How much information to print? This is a wrapper around
  [`req_verbose()`](https://httr2.r-lib.org/dev/reference/req_verbose.md)
  that uses an integer to control verbosity:

  - `0`: no output

  - `1`: show headers

  - `2`: show headers and bodies

  - `3`: show headers, bodies, and curl status messages.

  Use `with_verbosity()` to control the verbosity of requests that you
  can't affect directly.

- env:

  Environment to use for scoping changes.

## Value

`with_verbosity()` returns the result of evaluating `code`.
`local_verbosity()` is called for its side-effect and invisibly returns
the previous value of the option.

## Examples

``` r
fun <- function() {
  request("https://httr2.r-lib.org") |> req_perform()
}
with_verbosity(fun())
#> -> GET / HTTP/2
#> -> Host: httr2.r-lib.org
#> -> User-Agent: httr2/1.2.2.9000 r-curl/7.0.0 libcurl/8.5.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- x-origin-cache: HIT
#> <- last-modified: Mon, 08 Dec 2025 15:04:45 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6936e90d-4b79"
#> <- expires: Wed, 14 Jan 2026 19:22:26 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: BB10:386A84:26DEE2:27C2BA:6967EA99
#> <- accept-ranges: bytes
#> <- date: Wed, 14 Jan 2026 19:12:47 GMT
#> <- via: 1.1 varnish
#> <- age: 22
#> <- x-served-by: cache-sjc10072-SJC
#> <- x-cache: HIT
#> <- x-cache-hits: 5
#> <- x-timer: S1768417968.997781,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: ad56e2fe0bd139bf5130e6eb586a6144712baaea
#> <- content-length: 4833
#> <- 
#> <httr2_response>
#> GET https://httr2.r-lib.org/
#> Status: 200 OK
#> Content-Type: text/html
#> Body: In memory (19321 bytes)

fun <- function() {
  local_verbosity(2)
  # someotherpackage::fun()
}
```
