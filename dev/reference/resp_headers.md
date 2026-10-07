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
#> last-modified: Wed, 07 Oct 2026 13:53:32 GMT
#> access-control-allow-origin: *
#> etag: W/"6ac64edc-4c24"
#> expires: Wed, 07 Oct 2026 14:04:05 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: D36E:28A1CF:186D78:1D4428:6AC64EFD
#> x-github-edge-region: iad
#> accept-ranges: bytes
#> date: Wed, 07 Oct 2026 13:54:23 GMT
#> via: 1.1 varnish
#> age: 17
#> x-served-by: cache-iad-kcgs7200058-IAD
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1791381263.491775,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 9ccb531e21bf3393af22d33f5052666e273b32dd
#> content-length: 4860
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: D36E:28A1CF:186D78:1D4428:6AC64EFD
#> x-github-edge-region: iad
#> x-served-by: cache-iad-kcgs7200058-IAD
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1791381263.491775,VS0,VE0
#> x-fastly-request-id: 9ccb531e21bf3393af22d33f5052666e273b32dd

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
