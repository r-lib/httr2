# Get request method

Defaults to `GET`, unless the request has a body, in which case it uses
`POST`. Either way the method can be overridden with
[`req_method()`](https://httr2.r-lib.org/reference/req_method.md).

## Usage

``` r
req_get_method(req)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

## Examples

``` r
req <- request(example_url())
req_get_method(req)
#> [1] "GET"
req_get_method(req |> req_body_raw("abc"))
#> [1] "POST"
req_get_method(req |> req_method("DELETE"))
#> [1] "DELETE"
req_get_method(req |> req_method("HEAD"))
#> [1] "HEAD"
```
