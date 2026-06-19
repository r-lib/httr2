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

  Header name (case insensitive)

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
#> last-modified: Fri, 19 Jun 2026 13:17:09 GMT
#> access-control-allow-origin: *
#> etag: W/"6a354155-4b79"
#> expires: Fri, 19 Jun 2026 13:30:18 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 9DE0:284140:13B7DAC:1452395:6A354212
#> accept-ranges: bytes
#> date: Fri, 19 Jun 2026 13:20:19 GMT
#> via: 1.1 varnish
#> age: 1
#> x-served-by: cache-bfi-krnt7300117-BFI
#> x-cache: HIT
#> x-cache-hits: 3
#> x-timer: S1781875220.988881,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 9f2bedd0b69d16aa8c7733e5a473e77a1c8256e0
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 9DE0:284140:13B7DAC:1452395:6A354212
#> x-served-by: cache-bfi-krnt7300117-BFI
#> x-cache: HIT
#> x-cache-hits: 3
#> x-timer: S1781875220.988881,VS0,VE0
#> x-fastly-request-id: 9f2bedd0b69d16aa8c7733e5a473e77a1c8256e0

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
