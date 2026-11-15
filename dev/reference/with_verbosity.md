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

  Code to execute.

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
#> -> User-Agent: httr2/1.3.0.9000 r-curl/8.1.0 libcurl/8.18.0
#> -> Accept: */*
#> -> Accept-Encoding: deflate, gzip, br, zstd
#> -> 
#> <- HTTP/2 200 
#> <- server: GitHub.com
#> <- content-type: text/html; charset=utf-8
#> <- last-modified: Sun, 15 Nov 2026 14:19:38 GMT
#> <- access-control-allow-origin: *
#> <- etag: W/"6af9bf7a-4c24"
#> <- expires: Sun, 15 Nov 2026 14:29:46 GMT
#> <- cache-control: max-age=600
#> <- content-encoding: gzip
#> <- x-proxy-cache: MISS
#> <- x-github-request-id: 4D0C:6AE1F:2EEAEE0:338B44E:6AF9BF82
#> <- x-github-edge-region: iad
#> <- accept-ranges: bytes
#> <- date: Sun, 15 Nov 2026 14:19:50 GMT
#> <- via: 1.1 varnish
#> <- age: 4
#> <- x-served-by: cache-iad-kcgs7200042-IAD
#> <- x-cache: HIT
#> <- x-cache-hits: 4
#> <- x-timer: S1794752390.307660,VS0,VE0
#> <- vary: Accept-Encoding
#> <- x-fastly-request-id: 64adba5727d9a86eeefcf228d615959ab1c3967c
#> <- content-length: 4860
#> <- 
#> <httr2_response>
#> GET https://httr2.r-lib.org/
#> Status: 200 OK
#> Content-Type: text/html
#> Body: In memory (19492 bytes)

fun <- function() {
  local_verbosity(2)
  # someotherpackage::fun()
}
```
