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
#> last-modified: Mon, 05 Oct 2026 18:07:08 GMT
#> access-control-allow-origin: *
#> etag: W/"6ac3e74c-4c24"
#> expires: Mon, 05 Oct 2026 19:53:53 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: CD9E:54A8:7CE8F3:83729C:6AC3FDF6
#> x-github-edge-region: iad
#> accept-ranges: bytes
#> date: Mon, 05 Oct 2026 21:11:27 GMT
#> via: 1.1 varnish
#> age: 19
#> x-served-by: cache-dfw-kdfw8210163-DFW
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1791234688.986786,VS0,VE1
#> vary: Accept-Encoding
#> x-fastly-request-id: f61bdf393f4ccb48db71119c9326c0fb8d0428cf
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: CD9E:54A8:7CE8F3:83729C:6AC3FDF6
#> x-github-edge-region: iad
#> x-served-by: cache-dfw-kdfw8210163-DFW
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1791234688.986786,VS0,VE1
#> x-fastly-request-id: f61bdf393f4ccb48db71119c9326c0fb8d0428cf

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
