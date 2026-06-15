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
#> last-modified: Tue, 03 Mar 2026 22:14:50 GMT
#> access-control-allow-origin: *
#> etag: W/"69a75d5a-4b79"
#> expires: Mon, 15 Jun 2026 20:04:51 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 5FE8:D5CD3:584E2:5A9E2:6A30588B
#> accept-ranges: bytes
#> date: Mon, 15 Jun 2026 19:55:10 GMT
#> via: 1.1 varnish
#> age: 18
#> x-served-by: cache-hhr-khhr2060046-HHR
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1781553310.473289,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 2dc92db2b247313b138a7c362887992a3da1c1e7
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 5FE8:D5CD3:584E2:5A9E2:6A30588B
#> x-served-by: cache-hhr-khhr2060046-HHR
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1781553310.473289,VS0,VE0
#> x-fastly-request-id: 2dc92db2b247313b138a7c362887992a3da1c1e7

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
