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
#> last-modified: Mon, 15 Jun 2026 19:56:22 GMT
#> access-control-allow-origin: *
#> etag: W/"6a3058e6-4b79"
#> expires: Wed, 17 Jun 2026 16:39:42 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 9E76:299019:100B5A0:1219543:6A32CB75
#> accept-ranges: bytes
#> date: Wed, 17 Jun 2026 16:29:58 GMT
#> via: 1.1 varnish
#> age: 16
#> x-served-by: cache-chi-kmdw8640085-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1781713798.328930,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 0b1271c77265a50936b029fae1cae118b25783aa
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 9E76:299019:100B5A0:1219543:6A32CB75
#> x-served-by: cache-chi-kmdw8640085-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1781713798.328930,VS0,VE0
#> x-fastly-request-id: 0b1271c77265a50936b029fae1cae118b25783aa

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
