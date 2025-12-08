# httr2

httr2 (pronounced “hitter2”) is a comprehensive HTTP client that
provides a modern, pipeable API for working with web APIs. It builds on
top of [{curl}](https://jeroen.r-universe.dev/curl) to provide features
like explicit request objects, built-in rate limiting & retry tooling,
comprehensive OAuth support, and secure handling of secrets and
credentials.

## Installation

You can install httr2 from CRAN with:

``` r
install.packages("httr2")
```

## Usage

To use httr2, start by creating a **request**:

``` r
library(httr2)

req <- request("https://r-project.org")
req
#> <httr2_request>
#> GET https://r-project.org
#> Body: empty
```

You can tailor this request with the `req_` family of functions:

``` r
# Add custom headers
req |> req_headers("Accept" = "application/json")
#> <httr2_request>
#> GET https://r-project.org
#> Headers:
#> * Accept: "application/json"
#> Body: empty

# Add a body, turning it into a POST
req |> req_body_json(list(x = 1, y = 2))
#> <httr2_request>
#> POST https://r-project.org
#> Body: JSON data

# Modify the path in the url
req |> req_url_path(path = "path/to/my/file")
#> <httr2_request>
#> GET https://r-project.org/path/to/my/file
#> Body: empty

# Automatically retry if the request fails
req |> req_retry(max_tries = 5)
#> <httr2_request>
#> GET https://r-project.org
#> Body: empty
#> Policies:
#> * retry_max_tries        : 5
#> * retry_on_failure       : FALSE
#> * retry_failure_threshold: Inf
#> * retry_failure_timeout  : 30
#> * retry_realm            : "r-project.org"

# Change the HTTP method
req |> req_method("PATCH")
#> <httr2_request>
#> PATCH https://r-project.org
#> Body: empty
```

And see exactly what httr2 will send to the server with
[`req_dry_run()`](https://httr2.r-lib.org/dev/reference/req_dry_run.md):

``` r
req |> req_dry_run()
#> GET / HTTP/1.1
#> accept: */*
#> accept-encoding: deflate, gzip
#> host: r-project.org
#> user-agent: httr2/1.2.1.9000 r-curl/7.0.0 libcurl/8.14.1
```

Use
[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
to perform the request, retrieving a **response**:

``` r
resp <- req_perform(req)
resp
#> <httr2_response>
#> GET https://www.r-project.org/
#> Status: 200 OK
#> Content-Type: text/html
#> Body: In memory (6238 bytes)
```

The `resp_` functions help you extract various useful components of the
response:

``` r
resp |> resp_content_type()
#> [1] "text/html"
resp |> resp_status_desc()
#> [1] "OK"
resp |> resp_body_html()
#> {html_document}
#> <html lang="en">
#> [1] <head>\n<meta http-equiv="Content-Type" content="text/html; charset=UTF-8 ...
#> [2] <body>\n    <div class="container page">\n      <div class="row">\n       ...
```

## Major differences to httr

- You can now create and modify a request without performing it. This
  means that there’s now a single function to perform the request and
  fetch the result:
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
  replaces [`httr::GET()`](https://httr.r-lib.org/reference/GET.html),
  [`httr::POST()`](https://httr.r-lib.org/reference/POST.html),
  [`httr::DELETE()`](https://httr.r-lib.org/reference/DELETE.html), and
  more.

- HTTP errors are automatically converted into R errors. Use
  [`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md) to
  override the defaults (which turn all 4xx and 5xx responses into
  errors) or to add additional details to the error message.

- You can automatically retry if the request fails or encounters a
  transient HTTP error (e.g. a 429 rate limit request).
  [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  defines the maximum number of retries, which errors are transient, and
  how long to wait between tries.

- OAuth support has been totally overhauled to directly support many
  more flows and to make it much easier to both customise the built-in
  flows and to create your own.

- You can manage secrets (often needed for testing) with
  [`secret_encrypt()`](https://httr2.r-lib.org/dev/reference/secrets.md)
  and friends. You can obfuscate mildly confidential data with
  [`obfuscate()`](https://httr2.r-lib.org/dev/reference/obfuscate.md),
  preventing it from being scraped from published code.

- You can automatically cache all cacheable results with
  [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md).
  Relatively few API responses are cacheable, but when they are it
  typically makes a big difference.

## Acknowledgements

httr2 wouldn’t be possible without [curl](https://cran.dev/curl/),
[openssl](https://cran.dev/openssl/),
[jsonlite](https://cran.dev/jsonlite/), and
[jose](https://github.com/r-lib/jose/), which are all maintained by
[Jeroen Ooms](https://github.com/jeroen). A big thanks also go to [Jenny
Bryan](https://jennybryan.org) and [Craig
Citro](https://www.craigcitro.org) who have given me much useful
feedback on both the design of the internals and the user facing API.
