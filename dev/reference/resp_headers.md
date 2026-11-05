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
#> last-modified: Thu, 05 Nov 2026 15:33:21 GMT
#> access-control-allow-origin: *
#> etag: W/"6aeca1c1-4c24"
#> expires: Thu, 05 Nov 2026 16:43:32 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: REVALIDATED
#> x-github-request-id: 767C:2C7F9D:8B2D2:98848:6AECB2B5
#> x-github-edge-region: iad
#> accept-ranges: bytes
#> date: Thu, 05 Nov 2026 16:45:55 GMT
#> via: 1.1 varnish
#> age: 14
#> x-served-by: cache-phx1710056-PHX
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1793897156.832075,VS0,VE2
#> vary: Accept-Encoding
#> x-fastly-request-id: cf3f04396a413f30cd4ff7822f96259df7bce9a8
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: REVALIDATED
#> x-github-request-id: 767C:2C7F9D:8B2D2:98848:6AECB2B5
#> x-github-edge-region: iad
#> x-served-by: cache-phx1710056-PHX
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1793897156.832075,VS0,VE2
#> x-fastly-request-id: cf3f04396a413f30cd4ff7822f96259df7bce9a8

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
