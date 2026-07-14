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
#> last-modified: Tue, 14 Jul 2026 13:26:45 GMT
#> access-control-allow-origin: *
#> etag: W/"6a563915-4c24"
#> expires: Tue, 14 Jul 2026 13:36:45 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: AC3E:344B64:B3CBE9:CD72B3:6A563915
#> accept-ranges: bytes
#> date: Tue, 14 Jul 2026 13:28:22 GMT
#> via: 1.1 varnish
#> age: 17
#> x-served-by: cache-iad-kiad7000033-IAD
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1784035703.866141,VS0,VE1
#> vary: Accept-Encoding
#> x-fastly-request-id: dbf35f3d2d82aeb4a64617e338ea3c2bed0dd672
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: AC3E:344B64:B3CBE9:CD72B3:6A563915
#> x-served-by: cache-iad-kiad7000033-IAD
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1784035703.866141,VS0,VE1
#> x-fastly-request-id: dbf35f3d2d82aeb4a64617e338ea3c2bed0dd672

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
