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
#> last-modified: Thu, 18 Jun 2026 16:14:04 GMT
#> access-control-allow-origin: *
#> etag: W/"6a34194c-4b79"
#> expires: Thu, 18 Jun 2026 22:14:51 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: D4A6:50439:1C7BFEF:1E3E389:6A346B83
#> accept-ranges: bytes
#> date: Thu, 18 Jun 2026 22:27:30 GMT
#> via: 1.1 varnish
#> age: 473
#> x-served-by: cache-iad-kiad7000179-IAD
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1781821650.090885,VS0,VE45
#> vary: Accept-Encoding
#> x-fastly-request-id: 2c727f2a7fad804bc39c752070e9596f1c762a3a
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: D4A6:50439:1C7BFEF:1E3E389:6A346B83
#> x-served-by: cache-iad-kiad7000179-IAD
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1781821650.090885,VS0,VE45
#> x-fastly-request-id: 2c727f2a7fad804bc39c752070e9596f1c762a3a

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
