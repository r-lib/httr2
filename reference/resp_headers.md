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

  A httr2 [response](https://httr2.r-lib.org/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md).

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
#> last-modified: Mon, 13 Jul 2026 19:57:01 GMT
#> access-control-allow-origin: *
#> etag: W/"6a55430d-4ba0"
#> expires: Tue, 14 Jul 2026 08:41:24 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 130C:2308F9:2CFC12:2EC791:6A55F3DC
#> accept-ranges: bytes
#> date: Tue, 14 Jul 2026 13:25:50 GMT
#> via: 1.1 varnish
#> age: 21
#> x-served-by: cache-bur-kbur8200051-BUR
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1784035550.395987,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: df30b1e0231645d27cac188af75a2740a58de386
#> content-length: 4831
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 130C:2308F9:2CFC12:2EC791:6A55F3DC
#> x-served-by: cache-bur-kbur8200051-BUR
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1784035550.395987,VS0,VE0
#> x-fastly-request-id: df30b1e0231645d27cac188af75a2740a58de386

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
