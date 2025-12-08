# Extract request date from response

All responses contain a request date in the `Date` header; if not
provided by the server will be automatically added by httr2.

## Usage

``` r
resp_date(resp)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md).

## Value

A `POSIXct` date-time.

## Examples

``` r
resp <- response(headers = "Date: Wed, 01 Jan 2020 09:23:15 UTC")
resp |> resp_date()
#> [1] "2020-01-01 09:23:15 UTC"

# If server doesn't add header (unusual), you get the time the request
# was created:
resp <- response()
resp |> resp_date()
#> [1] "2020-01-01 UTC"
```
