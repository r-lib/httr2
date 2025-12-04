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
#> x-origin-cache: HIT
#> last-modified: Thu, 04 Dec 2025 23:07:14 GMT
#> access-control-allow-origin: *
#> etag: W/"69321422-4ae0"
#> expires: Thu, 04 Dec 2025 23:20:16 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 9CEE:149B8D:1AACBED:1D3E858:693214D8
#> accept-ranges: bytes
#> date: Thu, 04 Dec 2025 23:10:47 GMT
#> via: 1.1 varnish
#> age: 0
#> x-served-by: cache-iad-kcgs7200109-IAD
#> x-cache: HIT
#> x-cache-hits: 1
#> x-timer: S1764889848.743465,VS0,VE10
#> vary: Accept-Encoding
#> x-fastly-request-id: 9020857c3221c0d1869a298d97f3c3e082a630ab
#> content-length: 4768
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-origin-cache: HIT
#> x-proxy-cache: MISS
#> x-github-request-id: 9CEE:149B8D:1AACBED:1D3E858:693214D8
#> x-served-by: cache-iad-kcgs7200109-IAD
#> x-cache: HIT
#> x-cache-hits: 1
#> x-timer: S1764889848.743465,VS0,VE10
#> x-fastly-request-id: 9020857c3221c0d1869a298d97f3c3e082a630ab

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
