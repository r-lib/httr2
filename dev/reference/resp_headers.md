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
#> last-modified: Sun, 21 Jun 2026 16:12:07 GMT
#> access-control-allow-origin: *
#> etag: W/"6a380d57-4b79"
#> expires: Mon, 22 Jun 2026 20:09:45 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 612A:36ED15:17FA1A:18E2C6:6A399431
#> accept-ranges: bytes
#> date: Mon, 22 Jun 2026 22:03:23 GMT
#> via: 1.1 varnish
#> age: 300
#> x-served-by: cache-pao-kpao1770074-PAO
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1782165804.609189,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: cc6b770c75eeaf216cae16ad65bef28e202fde16
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 612A:36ED15:17FA1A:18E2C6:6A399431
#> x-served-by: cache-pao-kpao1770074-PAO
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1782165804.609189,VS0,VE0
#> x-fastly-request-id: cc6b770c75eeaf216cae16ad65bef28e202fde16

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
