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
#> last-modified: Wed, 14 Jan 2026 19:13:41 GMT
#> access-control-allow-origin: *
#> etag: W/"6967eae5-4b79"
#> expires: Wed, 14 Jan 2026 19:35:42 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 0EFE:3B4011:4162F9:477857:6967EDB5
#> accept-ranges: bytes
#> date: Wed, 14 Jan 2026 19:31:52 GMT
#> via: 1.1 varnish
#> age: 155
#> x-served-by: cache-chi-kigq8000115-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1768419113.789051,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: efe1288d1af51fc87d33d5531c44e6cb902b399a
#> content-length: 4833
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 0EFE:3B4011:4162F9:477857:6967EDB5
#> x-served-by: cache-chi-kigq8000115-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1768419113.789051,VS0,VE0
#> x-fastly-request-id: efe1288d1af51fc87d33d5531c44e6cb902b399a

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
