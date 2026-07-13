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
#> last-modified: Sat, 11 Jul 2026 18:56:14 GMT
#> access-control-allow-origin: *
#> etag: W/"6a5291ce-4ba0"
#> expires: Mon, 13 Jul 2026 17:32:01 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 4D54:3BEC8D:19BC483:1ABBC0C:6A551EB8
#> accept-ranges: bytes
#> date: Mon, 13 Jul 2026 17:26:04 GMT
#> via: 1.1 varnish
#> age: 22
#> x-served-by: cache-sjc10050-SJC
#> x-cache: HIT
#> x-cache-hits: 5
#> x-timer: S1783963564.090480,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 2637ab2d9b0ffc115613a02d57e651c050d15a51
#> content-length: 4831
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 4D54:3BEC8D:19BC483:1ABBC0C:6A551EB8
#> x-served-by: cache-sjc10050-SJC
#> x-cache: HIT
#> x-cache-hits: 5
#> x-timer: S1783963564.090480,VS0,VE0
#> x-fastly-request-id: 2637ab2d9b0ffc115613a02d57e651c050d15a51

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
