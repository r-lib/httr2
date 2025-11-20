# Control handling of HTTP errors

[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
will automatically convert HTTP errors (i.e. any 4xx or 5xx status code)
into R errors. Use `req_error()` to either override the defaults, or
extract additional information from the response that would be useful to
expose to the user.

## Usage

``` r
req_error(req, is_error = NULL, body = NULL)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- is_error:

  A predicate function that takes a single argument (the response) and
  returns `TRUE` or `FALSE` indicating whether or not an R error should
  be signalled.

- body:

  A callback function that takes a single argument (the response) and
  returns a character vector of additional information to include in the
  body of the error. This vector is passed along to the `message`
  argument of
  [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html) so
  you can use any formatting that it supports.

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## Error handling

[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
is designed to succeed if and only if you get a valid HTTP response.
There are two ways a request can fail:

- The HTTP request might fail, for example if the connection is dropped
  or the server doesn't exist. This type of error will have class
  `c("httr2_failure", "httr2_error")`.

- The HTTP request might succeed, but return an HTTP status code that
  represents an error, e.g. a `404 Not Found` if the specified resource
  is not found. This type of error will have (e.g.) class
  `c("httr2_http_404", "httr2_http", "httr2_error")`.

These error classes are designed to be used in conjunction with R's
condition handling tools (<https://adv-r.hadley.nz/conditions.html>).
For example, if you want to return a default value when the server
returns a 404, use
[`tryCatch()`](https://rdrr.io/r/base/conditions.html):

    tryCatch(
      req |> req_perform() |> resp_body_json(),
      httr2_http_404 = function(cnd) NULL
    )

Or if you want to re-throw the error with some additional context, use
[`withCallingHandlers()`](https://rdrr.io/r/base/conditions.html), e.g.:

    withCallingHandlers(
      req |> req_perform() |> resp_body_json(),
      httr2_http_404 = function(cnd) {
        rlang::abort("Couldn't find user", parent = cnd)
      }
    )

Learn more about error chaining at
[rlang::topic-error-chaining](https://rlang.r-lib.org/reference/topic-error-chaining.html).

## See also

[`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md) to
control when errors are automatically retried.

## Examples

``` r
# Performing this request usually generates an error because httr2
# converts HTTP errors into R errors:
req <- request(example_url()) |>
  req_url_path("/status/404")
try(req |> req_perform())
#> Error in req_perform(req) : HTTP 404 Not Found.
# You can still retrieve it with last_response()
last_response()
#> <httr2_response>
#> GET http://127.0.0.1:36963/status/404
#> Status: 404 Not Found
#> Content-Type: text/plain
#> Body: None

# But you might want to suppress this behaviour:
resp <- req |>
  req_error(is_error = \(resp) FALSE) |>
  req_perform()
resp
#> <httr2_response>
#> GET http://127.0.0.1:36963/status/404
#> Status: 404 Not Found
#> Content-Type: text/plain
#> Body: None

# Or perhaps you're working with a server that routinely uses the
# wrong HTTP error codes only 500s are really errors
request("http://example.com") |>
  req_error(is_error = \(resp) resp_status(resp) == 500)
#> <httr2_request>
#> GET http://example.com
#> Body: empty
#> Policies:
#> * error_is_error: <function>

# Most typically you'll use req_error() to add additional information
# extracted from the response body (or sometimes header):
error_body <- function(resp) {
  resp_body_json(resp)$error
}
request("http://example.com") |>
  req_error(body = error_body)
#> <httr2_request>
#> GET http://example.com
#> Body: empty
#> Policies:
#> * error_body: <function>
# Learn more in https://httr2.r-lib.org/articles/wrapping-apis.html
```
