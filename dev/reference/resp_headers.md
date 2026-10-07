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
#> last-modified: Tue, 06 Oct 2026 22:53:49 GMT
#> access-control-allow-origin: *
#> etag: W/"6ac57bfd-4c24"
#> expires: Wed, 07 Oct 2026 14:01:24 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 4B96:22C435:24DC9D:281762:6AC64E5C
#> x-github-edge-region: iad
#> accept-ranges: bytes
#> date: Wed, 07 Oct 2026 13:51:41 GMT
#> via: 1.1 varnish
#> age: 16
#> x-served-by: cache-phx1710093-PHX
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1791381101.381034,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 335e9e08c942de63b9a87903163cc7f0aab5f171
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 4B96:22C435:24DC9D:281762:6AC64E5C
#> x-github-edge-region: iad
#> x-served-by: cache-phx1710093-PHX
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1791381101.381034,VS0,VE0
#> x-fastly-request-id: 335e9e08c942de63b9a87903163cc7f0aab5f171

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
