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
#> last-modified: Wed, 17 Jun 2026 16:32:51 GMT
#> access-control-allow-origin: *
#> etag: W/"6a32cc33-4b79"
#> expires: Thu, 18 Jun 2026 13:42:20 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: EF26:1C63CE:86EE5C:8B3B9F:6A33F364
#> accept-ranges: bytes
#> date: Thu, 18 Jun 2026 13:58:57 GMT
#> via: 1.1 varnish
#> age: 1
#> x-served-by: cache-pao-kpao1770025-PAO
#> x-cache: HIT
#> x-cache-hits: 3
#> x-timer: S1781791138.946562,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 39278a67a967489f080505a6ddabdc2f6f1b135f
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: EF26:1C63CE:86EE5C:8B3B9F:6A33F364
#> x-served-by: cache-pao-kpao1770025-PAO
#> x-cache: HIT
#> x-cache-hits: 3
#> x-timer: S1781791138.946562,VS0,VE0
#> x-fastly-request-id: 39278a67a967489f080505a6ddabdc2f6f1b135f

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
