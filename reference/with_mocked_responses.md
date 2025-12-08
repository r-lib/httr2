# Temporarily mock requests

Mocking allows you to selectively and temporarily replace the response
you would typically receive from a request with your own code. These
functions are low-level and we don't recommend using them directly.
Instead use package that uses these functions under the hood, like
httptest2 or vcr.

## Usage

``` r
with_mocked_responses(mock, code)

local_mocked_responses(mock, env = caller_env())
```

## Arguments

- mock:

  A function, a list, or `NULL`.

  - `NULL` disables mocking and returns httr2 to regular operation.

  - A list of responses will be returned in sequence. After all
    responses have been used up, will return 503 server errors.

  - For maximum flexibility, you can supply a function that that takes a
    single argument, `req`, and returns either `NULL` (if it doesn't
    want to handle the request) or a
    [response](https://httr2.r-lib.org/reference/response.md) (if it
    does).

- code:

  Code to execute in the temporary environment.

- env:

  Environment to use for scoping changes.

## Value

`with_mocked_responses()` returns the result of evaluating `code`.

## Examples

``` r
# This function should perform a response against google.com:
google <- function() {
  request("http://google.com") |>
    req_perform()
}

# But I can use a mock to instead return my own made up response:
my_mock <- function(req) {
  response(status_code = 403)
}
try(with_mocked_responses(my_mock, google()))
#> Error in req_perform(request("http://google.com")) : 
#>   HTTP 403 Forbidden.
```
