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
#> last-modified: Fri, 05 Dec 2025 16:50:44 GMT
#> access-control-allow-origin: *
#> etag: W/"69330d64-4ae0"
#> expires: Fri, 05 Dec 2025 17:01:29 GMT
#> cache-control: max-age=600
#> content-encoding: gzip
#> x-proxy-cache: MISS
#> x-github-request-id: 7A9B:294EAB:3578D8:38B150:69330D91
#> accept-ranges: bytes
#> date: Fri, 05 Dec 2025 16:52:22 GMT
#> via: 1.1 varnish
#> age: 17
#> x-served-by: cache-chi-kigq8000178-CHI
#> x-cache: HIT
#> x-cache-hits: 5
#> x-timer: S1764953543.596852,VS0,VE0
#> vary: Accept-Encoding
#> x-fastly-request-id: b070a88b2eea9b71ef2833e6469a14b7e65d697c
#> content-length: 4768
resp |> resp_headers("x-")
#> <httr2_headers>
#> x-proxy-cache: MISS
#> x-github-request-id: 7A9B:294EAB:3578D8:38B150:69330D91
#> x-served-by: cache-chi-kigq8000178-CHI
#> x-cache: HIT
#> x-cache-hits: 5
#> x-timer: S1764953543.596852,VS0,VE0
#> x-fastly-request-id: b070a88b2eea9b71ef2833e6469a14b7e65d697c

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
