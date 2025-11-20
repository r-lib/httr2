# Create a HTTP response

This is the constructor function for the `httr2_response` S3 class. It
is useful primarily for mocking.

## Usage

``` r
new_response(
  method,
  url,
  status_code,
  headers,
  body,
  timing = NULL,
  request = NULL,
  error_call = caller_env()
)
```

## Arguments

- method:

  HTTP method used to retrieve the response.

- url:

  URL response came from; might not be the same as the URL in the
  request if there were any redirects.

- status_code:

  HTTP status code. Must be a single integer.

- headers:

  HTTP headers. Can be supplied as a raw or character vector which will
  be parsed using the standard rules, or a named list.

- body:

  The body of the response. Can be a raw vector, a `<httr2_path>`, or a
  [StreamingBody](https://httr2.r-lib.org/dev/reference/StreamingBody.md).

- timing:

  A named numeric vector giving the time taken by various components.

- request:

  The [request](https://httr2.r-lib.org/dev/reference/request.md) used
  to generate this response.

- error_call:

  Environment (on call stack) used in error messages.

## Value

An HTTP response: an S3 list with class `httr2_response`.
