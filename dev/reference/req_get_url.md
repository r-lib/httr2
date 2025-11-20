# Get request URL

Retrieve the URL from a request.

## Usage

``` r
req_get_url(req)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

## Value

A character string.

## Examples

``` r
request("https://httpbin.org") |>
  req_url_path("/get") |>
  req_url_query(hello = "world") |>
  req_get_url()
#> [1] "https://httpbin.org/get?hello=world"
```
