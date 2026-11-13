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
#> last-modified: Fri, 13 Nov 2026 22:40:30 GMT
#> access-control-allow-origin: *
#> etag: W/"6af791de-4c24"
#> expires: Fri, 13 Nov 2026 22:52:42 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 9E60:F7DD7:12C6B:1E99B:6AF79262
#> x-github-edge-region: westus2
#> accept-ranges: bytes
#> date: Fri, 13 Nov 2026 22:43:13 GMT
#> via: 1.1 varnish
#> age: 0
#> x-served-by: cache-bfi-krnt7300063-BFI
#> x-cache: HIT
#> x-cache-hits: 1
#> x-timer: S1794609794.554423,VS0,VE84
#> vary: Accept-Encoding
#> x-fastly-request-id: ed2da0193c48411d8c2f665e5ccdc601b7618711
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 9E60:F7DD7:12C6B:1E99B:6AF79262
#> x-github-edge-region: westus2
#> x-served-by: cache-bfi-krnt7300063-BFI
#> x-cache: HIT
#> x-cache-hits: 1
#> x-timer: S1794609794.554423,VS0,VE84
#> x-fastly-request-id: ed2da0193c48411d8c2f665e5ccdc601b7618711

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
