# Extract wait time from a response

Computes how many seconds you should wait before retrying a request by
inspecting the `Retry-After` header. It parses both forms (absolute and
relative) and returns the number of seconds to wait. If the heading is
not found, it will return `NA`.

## Usage

``` r
resp_retry_after(resp)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/dev/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

## Value

Scalar double giving the number of seconds to wait before retrying a
request.

## Examples

``` r
resp <- response(headers = "Retry-After: 30")
resp |> resp_retry_after()
#> [1] 30

resp <- response(headers = "Retry-After: Mon, 20 Sep 2025 21:44:05 UTC")
resp |> resp_retry_after()
#> [1] 180567845
```
