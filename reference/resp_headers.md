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
#> last-modified: Fri, 05 Dec 2025 16:53:35 GMT
#> access-control-allow-origin: *
#> etag: W/"69330e0f-4ae0"
#> expires: Mon, 08 Dec 2025 13:08:34 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 1074:1D670E:1929564:19FD3B9:6936CB79
#> accept-ranges: bytes
#> date: Mon, 08 Dec 2025 15:00:55 GMT
#> via: 1.1 varnish
#> age: 22
#> x-served-by: cache-sjc10050-SJC
#> x-cache: HIT
#> x-cache-hits: 5
#> x-timer: S1765206056.557257,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: 8411db97ddd430edff35db7472e19f75e5351205
#> content-length: 4768
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 1074:1D670E:1929564:19FD3B9:6936CB79
#> x-served-by: cache-sjc10050-SJC
#> x-cache: HIT
#> x-cache-hits: 5
#> x-timer: S1765206056.557257,VS0,VE0
#> x-fastly-request-id: 8411db97ddd430edff35db7472e19f75e5351205

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
