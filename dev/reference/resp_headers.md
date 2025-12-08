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
#> last-modified: Mon, 08 Dec 2025 15:02:17 GMT
#> access-control-allow-origin: *
#> etag: W/"6936e879-4b79"
#> expires: Mon, 08 Dec 2025 15:13:22 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 4476:135A:7259CB:768AA7:6936E8B9
#> accept-ranges: bytes
#> date: Mon, 08 Dec 2025 15:03:39 GMT
#> via: 1.1 varnish
#> age: 18
#> x-served-by: cache-pao-kpao1770022-PAO
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1765206219.412412,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 303661743a4c2f09e2c3b8b9f5bd64a645c2ae5d
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 4476:135A:7259CB:768AA7:6936E8B9
#> x-served-by: cache-pao-kpao1770022-PAO
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1765206219.412412,VS0,VE0
#> x-fastly-request-id: 303661743a4c2f09e2c3b8b9f5bd64a645c2ae5d

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
