# Check the content type of a response

A different content type than expected often leads to an error in
parsing the response body. This function checks that the content type of
the response is as expected and fails otherwise.

## Usage

``` r
resp_check_content_type(
  resp,
  valid_types = NULL,
  valid_suffix = NULL,
  check_type = TRUE,
  call = caller_env()
)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/dev/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

- valid_types:

  A character vector of valid MIME types. Should only be specified with
  `type/subtype`.

- valid_suffix:

  A string given an "structured media type" suffix.

- check_type:

  Should the type actually be checked? Provided as a convenience for
  when using this function inside `resp_body_*` helpers.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

Called for its side-effect; erroring if the response does not have the
expected content type.

## Examples

``` r
resp <- response(headers = list(`content-type` = "application/json"))
resp_check_content_type(resp, "application/json")
try(resp_check_content_type(resp, "application/xml"))
#> Error in eval(expr, envir) : 
#>   Unexpected content type "application/json".
#> • Expecting type "application/xml"

# `types` can also specify multiple valid types
resp_check_content_type(resp, c("application/xml", "application/json"))
```
