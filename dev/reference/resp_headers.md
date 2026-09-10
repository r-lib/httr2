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
#> last-modified: Tue, 08 Sep 2026 12:29:51 GMT
#> access-control-allow-origin: *
#> etag: W/"6a9fffbf-4c24"
#> expires: Tue, 08 Sep 2026 12:43:51 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 0D1C:181CF5:16711FF:18A6AD9:6AA000AF
#> x-github-edge-region: iad
#> accept-ranges: bytes
#> date: Thu, 10 Sep 2026 14:57:59 GMT
#> via: 1.1 varnish
#> age: 538
#> x-served-by: cache-chi-kmdw8640023-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1789052279.119955,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 72f48b35b0621ae1d1370ef24a4662925b04b051
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 0D1C:181CF5:16711FF:18A6AD9:6AA000AF
#> x-github-edge-region: iad
#> x-served-by: cache-chi-kmdw8640023-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1789052279.119955,VS0,VE0
#> x-fastly-request-id: 72f48b35b0621ae1d1370ef24a4662925b04b051

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
