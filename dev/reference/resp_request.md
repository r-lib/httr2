# Find the request responsible for a response

To make debugging easier, httr2 includes the request that was used to
generate every response. You can use this function to access it.

## Usage

``` r
resp_request(resp)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/dev/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

## Examples

``` r
req <- request(example_url())
resp <- req_perform(req)
resp_request(resp)
#> <httr2_request>
#> GET http://127.0.0.1:39853/
#> Body: empty
```
