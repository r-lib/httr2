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
#> last-modified: Fri, 13 Nov 2026 22:44:03 GMT
#> access-control-allow-origin: *
#> etag: W/"6af792b3-4c24"
#> expires: Sat, 14 Nov 2026 11:58:45 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 9850:1F1B68:F57610:126C36D:6AF84A9D
#> x-github-edge-region: iad
#> accept-ranges: bytes
#> date: Sat, 14 Nov 2026 12:28:12 GMT
#> via: 1.1 varnish
#> age: 189
#> x-served-by: cache-iad-kcgs7200073-IAD
#> x-cache: HIT
#> x-cache-hits: 7
#> x-timer: S1794659292.226195,VS0,VE1
#> vary: Accept-Encoding
#> x-fastly-request-id: 6f6011a02ce6c5c845fb8baf1ef738c8fb8549ca
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 9850:1F1B68:F57610:126C36D:6AF84A9D
#> x-github-edge-region: iad
#> x-served-by: cache-iad-kcgs7200073-IAD
#> x-cache: HIT
#> x-cache-hits: 7
#> x-timer: S1794659292.226195,VS0,VE1
#> x-fastly-request-id: 6f6011a02ce6c5c845fb8baf1ef738c8fb8549ca

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
