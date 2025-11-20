# Create a HTTP response for testing

`response()` creates a generic response; `response_json()` creates a
response with a JSON body, automatically adding the correct
`Content-Type` header.

Generally, you should not need to call these function directly; you'll
get a real HTTP response by calling
[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
and friends. These function is provided primarily for use in tests; if
you are creating responses for mocked requests, use the lower-level
[`new_response()`](https://httr2.r-lib.org/dev/reference/new_response.md).

## Usage

``` r
response(
  status_code = 200,
  url = "https://example.com",
  method = "GET",
  headers = list(),
  body = raw(),
  timing = NULL
)

response_json(
  status_code = 200,
  url = "https://example.com",
  method = "GET",
  headers = list(),
  body = list()
)
```

## Arguments

- status_code:

  HTTP status code. Must be a single integer.

- url:

  URL response came from; might not be the same as the URL in the
  request if there were any redirects.

- method:

  HTTP method used to retrieve the response.

- headers:

  HTTP headers. Can be supplied as a raw or character vector which will
  be parsed using the standard rules, or a named list.

- body:

  The response body. For `response_json()`, a R data structure that will
  be serialized to JSON.

- timing:

  A named numeric vector giving the time taken by various components.

## Value

An HTTP response: an S3 list with class `httr2_response`.

## Examples

``` r
response()
#> <httr2_response>
#> GET https://example.com
#> Status: 200 OK
#> Body: None
response(404, method = "POST")
#> <httr2_response>
#> POST https://example.com
#> Status: 404 Not Found
#> Body: None
response(headers = c("Content-Type: text/html", "Content-Length: 300"))
#> <httr2_response>
#> GET https://example.com
#> Status: 200 OK
#> Content-Type: text/html
#> Body: None
```
