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
#> last-modified: Sat, 20 Jun 2026 02:33:31 GMT
#> access-control-allow-origin: *
#> etag: W/"6a35fbfb-4b79"
#> expires: Sun, 21 Jun 2026 16:09:42 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 8878:17F90:D67DC8:DEB20E:6A380A6D
#> accept-ranges: bytes
#> date: Sun, 21 Jun 2026 16:04:52 GMT
#> via: 1.1 varnish
#> age: 14
#> x-served-by: cache-sjc10057-SJC
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1782057893.652411,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 3facf8825682c98223ca8bf6156671efb0c872e5
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 8878:17F90:D67DC8:DEB20E:6A380A6D
#> x-served-by: cache-sjc10057-SJC
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1782057893.652411,VS0,VE0
#> x-fastly-request-id: 3facf8825682c98223ca8bf6156671efb0c872e5

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
