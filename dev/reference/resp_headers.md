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
#> last-modified: Sat, 14 Nov 2026 12:34:28 GMT
#> access-control-allow-origin: *
#> etag: W/"6af85554-4c24"
#> expires: Sat, 14 Nov 2026 12:52:39 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 6C0C:1D3C:B6467E:DBB5F6:6AF8573B
#> x-github-edge-region: iad
#> accept-ranges: bytes
#> date: Sat, 14 Nov 2026 14:19:43 GMT
#> via: 1.1 varnish
#> age: 427
#> x-served-by: cache-chi-kmdw8640091-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1794665984.606757,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: e563ab0d7d840c9a9d8126ca7b07073182c2d1d5
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 6C0C:1D3C:B6467E:DBB5F6:6AF8573B
#> x-github-edge-region: iad
#> x-served-by: cache-chi-kmdw8640091-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1794665984.606757,VS0,VE0
#> x-fastly-request-id: e563ab0d7d840c9a9d8126ca7b07073182c2d1d5

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
