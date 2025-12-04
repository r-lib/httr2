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
#> last-modified: Thu, 04 Dec 2025 23:22:34 GMT
#> access-control-allow-origin: *
#> etag: W/"693217ba-4ae0"
#> expires: Thu, 04 Dec 2025 23:32:41 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 496E:2214B2:1CC4329:1F61FC9:693217C0
#> accept-ranges: bytes
#> date: Thu, 04 Dec 2025 23:24:21 GMT
#> via: 1.1 varnish
#> age: 19
#> x-served-by: cache-chi-kigq8000048-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1764890661.462583,VS0,VE2
#> vary: Accept-Encoding
#> x-fastly-request-id: 2609878c59728cb43921cf46737b76658d1c851a
#> content-length: 4768
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 496E:2214B2:1CC4329:1F61FC9:693217C0
#> x-served-by: cache-chi-kigq8000048-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1764890661.462583,VS0,VE2
#> x-fastly-request-id: 2609878c59728cb43921cf46737b76658d1c851a

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
