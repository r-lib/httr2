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
#> last-modified: Thu, 04 Dec 2025 23:04:43 GMT
#> access-control-allow-origin: *
#> etag: W/"6932138b-4ae0"
#> expires: Thu, 04 Dec 2025 23:15:45 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 54EC:F1088:1C60A02:1EEF1C9:693213C9
#> accept-ranges: bytes
#> date: Thu, 04 Dec 2025 23:06:19 GMT
#> via: 1.1 varnish
#> age: 2
#> x-served-by: cache-chi-kigq8000077-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1764889579.094260,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: c3e238c2b5067a37a018832228ecf778e0698eaa
#> content-length: 4768
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 54EC:F1088:1C60A02:1EEF1C9:693213C9
#> x-served-by: cache-chi-kigq8000077-CHI
#> x-cache: HIT
#> x-cache-hits: 4
#> x-timer: S1764889579.094260,VS0,VE0
#> x-fastly-request-id: c3e238c2b5067a37a018832228ecf778e0698eaa

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
