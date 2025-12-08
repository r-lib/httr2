# Extract HTTP status from response

- `resp_status()` retrieves the numeric HTTP status code

- `resp_status_desc()` retrieves the brief textual description.

- `resp_is_error()` returns `TRUE` if the status code represents an
  error (i.e. a 4xx or 5xx status).

- `resp_check_status()` turns HTTPs errors into R errors.

These functions are mostly for internal use because in most cases you
will only ever see a 200 response:

- 1xx are handled internally by curl.

- 3xx redirects are automatically followed. You will only see them if
  you have deliberately suppressed redirects with
  `req |> req_options(followlocation = FALSE)`.

- 4xx client and 5xx server errors are automatically turned into R
  errors. You can stop them from being turned into R errors with
  [`req_error()`](https://httr2.r-lib.org/reference/req_error.md), e.g.
  `req |> req_error(is_error = \(resp) FALSE)`.

## Usage

``` r
resp_status(resp)

resp_status_desc(resp)

resp_is_error(resp)

resp_check_status(resp, info = NULL, error_call = caller_env())
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md).

- info:

  A character vector of additional information to include in the error
  message. Passed to
  [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html).

- error_call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

- `resp_status()` returns a scalar integer

- `resp_status_desc()` returns a string

- `resp_is_error()` returns `TRUE` or `FALSE`

- `resp_check_status()` invisibly returns the response if it's ok;
  otherwise it throws an error with class `httr2_http_{status}`.

## Examples

``` r
# An HTTP status code you're unlikely to see in the wild:
resp <- response(418)
resp |> resp_is_error()
#> [1] TRUE
resp |> resp_status()
#> [1] 418
resp |> resp_status_desc()
#> [1] "I'm a teapot"
```
