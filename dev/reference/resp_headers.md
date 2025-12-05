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
#> last-modified: Thu, 04 Dec 2025 23:25:14 GMT
#> access-control-allow-origin: *
#> etag: W/"6932185a-4ae0"
#> expires: Fri, 05 Dec 2025 13:58:58 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 56A2:191124:9EBF9C:AE80CC:6932E2CA
#> accept-ranges: bytes
#> date: Fri, 05 Dec 2025 14:12:12 GMT
#> via: 1.1 varnish
#> age: 17
#> x-served-by: cache-chi-kigq8000129-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1764943932.274158,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: b8f92da746fe9d5a45c3426940dff24f6465ae38
#> content-length: 4768
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 56A2:191124:9EBF9C:AE80CC:6932E2CA
#> x-served-by: cache-chi-kigq8000129-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1764943932.274158,VS0,VE0
#> x-fastly-request-id: b8f92da746fe9d5a45c3426940dff24f6465ae38

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
