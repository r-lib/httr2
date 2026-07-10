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
#> last-modified: Tue, 23 Jun 2026 12:31:45 GMT
#> access-control-allow-origin: *
#> etag: W/"6a3a7cb1-4ba0"
#> expires: Fri, 10 Jul 2026 20:16:23 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: D182:191289:A13F9:A822E:6A5150BE
#> accept-ranges: bytes
#> date: Fri, 10 Jul 2026 20:06:33 GMT
#> via: 1.1 varnish
#> age: 10
#> x-served-by: cache-pao-kpao1770050-PAO
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1783713993.200467,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 2be686ba18eecb981d62723246c743f87e010b30
#> content-length: 4831
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: D182:191289:A13F9:A822E:6A5150BE
#> x-served-by: cache-pao-kpao1770050-PAO
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1783713993.200467,VS0,VE0
#> x-fastly-request-id: 2be686ba18eecb981d62723246c743f87e010b30

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
