# Extract headers from a response

- `resp_headers()` retrieves a list of all headers.

- `resp_header()` retrieves a single header.

- `resp_header_exists()` checks if a header is present.

## Usage

``` r
resp_headers(resp, filter = NULL)

resp_header(resp, header, default = NULL)

resp_header_exists(resp, header)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/dev/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

- filter:

  A regular expression used to filter the header names. `NULL`, the
  default, returns all headers.

- header:

  Header name (case insensitive).

- default:

  Default value to use if header doesn't exist.

## Value

- `resp_headers()` returns a list.

- `resp_header()` returns a string if the header exists and `NULL`
  otherwise.

- `resp_header_exists()` returns `TRUE` or `FALSE`.

## Examples

``` r
resp <- request("https://httr2.r-lib.org") |> req_perform()
resp |> resp_headers()
#> <httr2_headers>
#> server: GitHub.com
#> content-type: text/html; charset=utf-8
#> last-modified: Sun, 15 Nov 2026 14:04:18 GMT
#> access-control-allow-origin: *
#> etag: W/"6af9bbe2-4c24"
#> expires: Sun, 15 Nov 2026 14:27:40 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: F05A:F6F1A:9AC215:A183A8:6AF9BF03
#> x-github-edge-region: uksouth
#> accept-ranges: bytes
#> date: Sun, 15 Nov 2026 14:17:54 GMT
#> via: 1.1 varnish
#> age: 14
#> x-served-by: cache-hhr-khhr2060043-HHR
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1794752274.112629,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 9587526724fede5d04934e230a008a50a90e4248
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: F05A:F6F1A:9AC215:A183A8:6AF9BF03
#> x-github-edge-region: uksouth
#> x-served-by: cache-hhr-khhr2060043-HHR
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1794752274.112629,VS0,VE0
#> x-fastly-request-id: 9587526724fede5d04934e230a008a50a90e4248

resp |> resp_header_exists("server")
#> [1] TRUE
resp |> resp_header("server")
#> [1] "GitHub.com"
# Headers are case insensitive
resp |> resp_header("SERVER")
#> [1] "GitHub.com"

# Returns NULL if header doesn't exist
resp |> resp_header("this-header-doesnt-exist")
#> NULL
```
