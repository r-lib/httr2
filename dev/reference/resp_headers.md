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
#> last-modified: Fri, 10 Jul 2026 20:07:32 GMT
#> access-control-allow-origin: *
#> etag: W/"6a515104-4ba0"
#> expires: Fri, 10 Jul 2026 20:22:12 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 9142:35DC8B:AE3FC:B57BD:6A51521C
#> accept-ranges: bytes
#> date: Fri, 10 Jul 2026 22:30:26 GMT
#> via: 1.1 varnish
#> age: 18
#> x-served-by: cache-sjc1000132-SJC
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1783722627.869530,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 0c11ac7a54b4814c2d9190c03ad77a3e153f607a
#> content-length: 4831
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 9142:35DC8B:AE3FC:B57BD:6A51521C
#> x-served-by: cache-sjc1000132-SJC
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1783722627.869530,VS0,VE0
#> x-fastly-request-id: 0c11ac7a54b4814c2d9190c03ad77a3e153f607a

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
