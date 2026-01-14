# Perform a request to get a response

After preparing a
[request](https://httr2.r-lib.org/dev/reference/request.md), call
`req_perform()` to perform it, fetching the results back to R as a
[response](https://httr2.r-lib.org/dev/reference/response.md).

The default HTTP method is `GET` unless a body (set by
[req_body_json](https://httr2.r-lib.org/dev/reference/req_body.md) and
friends) is present, in which case it will be `POST`. You can override
these defaults with
[`req_method()`](https://httr2.r-lib.org/dev/reference/req_method.md).

## Usage

``` r
req_perform(
  req,
  path = NULL,
  verbosity = NULL,
  mock = getOption("httr2_mock", NULL),
  error_call = current_env()
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- path:

  Optionally, path to save body of the response. This is useful for
  large responses since it avoids storing the response in memory.

- verbosity:

  How much information to print? This is a wrapper around
  [`req_verbose()`](https://httr2.r-lib.org/dev/reference/req_verbose.md)
  that uses an integer to control verbosity:

  - `0`: no output

  - `1`: show headers

  - `2`: show headers and bodies

  - `3`: show headers, bodies, and curl status messages.

  Use
  [`with_verbosity()`](https://httr2.r-lib.org/dev/reference/with_verbosity.md)
  to control the verbosity of requests that you can't affect directly.

- mock:

  A mocking function. If supplied, this function is called with the
  request. It should return either `NULL` (if it doesn't want to handle
  the request) or a
  [response](https://httr2.r-lib.org/dev/reference/response.md) (if it
  does). See
  [`with_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)/[`local_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  for more details.

- error_call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

- If the HTTP request succeeds, and the status code is ok (e.g. 200), an
  HTTP [response](https://httr2.r-lib.org/dev/reference/response.md).

- If the HTTP request succeeds, but the status code is an error (e.g a
  404), an error with class `c("httr2_http_404", "httr2_http")`. By
  default, all 400 and 500 status codes will be treated as an error, but
  you can customise this with
  [`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md).

- If the HTTP request fails (e.g. the connection is dropped or the
  server doesn't exist), an error with class `"httr2_failure"`.

## Requests

Note that one call to `req_perform()` may perform multiple HTTP
requests:

- If the `url` is redirected with a 301, 302, 303, or 307, curl will
  automatically follow the `Location` header to the new location.

- If you have configured retries with
  [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  and the request fails with a transient problem, `req_perform()` will
  try again after waiting a bit. See
  [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
  for details.

- If you are using OAuth, and the cached token has expired,
  `req_perform()` will get a new token either using the refresh token
  (if available) or by running the OAuth flow.

## Progress bar

`req_perform()` will automatically add a progress bar if it needs to
wait between requests for
[`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
or [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md).
You can turn the progress bar off (and just show the total time to wait)
by setting `options(httr2_progress = FALSE)`.

## See also

[`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
to perform multiple requests in parallel.
[`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md)
to perform multiple requests iteratively.

## Examples

``` r
request("https://google.com") |>
  req_perform()
#> <httr2_response>
#> GET https://www.google.com/
#> Status: 200 OK
#> Content-Type: text/html
#> Body: In memory (17522 bytes)
```
