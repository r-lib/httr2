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
#> x-origin-cache: HIT
#> last-modified: Sat, 20 Jun 2026 02:16:34 GMT
#> access-control-allow-origin: *
#> etag: W/"6a35f802-4b79"
#> expires: Sat, 20 Jun 2026 02:33:37 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 6AE4:165398:8911A8:915786:6A35F9A8
#> accept-ranges: bytes
#> date: Sat, 20 Jun 2026 02:32:35 GMT
#> via: 1.1 varnish
#> age: 16
#> x-served-by: cache-dfw-kdfw8210084-DFW
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1781922756.795650,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: ab14d6220b8e763d86275f1480eca0effecfdb2b
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-origin-cache: HIT
#> x-proxy-cache: MISS
#> x-github-request-id: 6AE4:165398:8911A8:915786:6A35F9A8
#> x-served-by: cache-dfw-kdfw8210084-DFW
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1781922756.795650,VS0,VE0
#> x-fastly-request-id: ab14d6220b8e763d86275f1480eca0effecfdb2b

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
