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
#> last-modified: Thu, 05 Nov 2026 15:23:11 GMT
#> access-control-allow-origin: *
#> etag: W/"6aec9f5f-4c24"
#> expires: Thu, 05 Nov 2026 15:42:05 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 47B6:1AD1EF:2A281F:2EC4C4:6AECA174
#> x-github-edge-region: iad
#> accept-ranges: bytes
#> date: Thu, 05 Nov 2026 15:32:25 GMT
#> via: 1.1 varnish
#> age: 20
#> x-served-by: cache-iad-kiad7000179-IAD
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1793892746.774903,VS0,VE1
#> vary: Accept-Encoding
#> x-fastly-request-id: 6901e0dcedb1900c31fbf66782b1f072bd9337f8
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 47B6:1AD1EF:2A281F:2EC4C4:6AECA174
#> x-github-edge-region: iad
#> x-served-by: cache-iad-kiad7000179-IAD
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1793892746.774903,VS0,VE1
#> x-fastly-request-id: 6901e0dcedb1900c31fbf66782b1f072bd9337f8

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
