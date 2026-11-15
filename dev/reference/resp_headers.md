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

  Header name (case insensitive).

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
#> last-modified: Sun, 15 Nov 2026 14:20:56 GMT
#> access-control-allow-origin: *
#> etag: W/"6af9bfc8-4c24"
#> expires: Sun, 15 Nov 2026 14:43:04 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 429C:2DE802:CE241:129220:6AF9C2A0
#> x-github-edge-region: westus2
#> accept-ranges: bytes
#> date: Sun, 15 Nov 2026 14:33:23 GMT
#> via: 1.1 varnish
#> age: 18
#> x-served-by: cache-bfi-krnt7300093-BFI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1794753203.449214,VS0,VE1
#> vary: Accept-Encoding
#> x-fastly-request-id: bdcf869556e69ba232b4d827814c5a032dca6118
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 429C:2DE802:CE241:129220:6AF9C2A0
#> x-github-edge-region: westus2
#> x-served-by: cache-bfi-krnt7300093-BFI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1794753203.449214,VS0,VE1
#> x-fastly-request-id: bdcf869556e69ba232b4d827814c5a032dca6118

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
