# Set HTTP method in request

Use this function to use a custom HTTP method like `HEAD`, `DELETE`,
`PATCH`, `UPDATE`, or `OPTIONS`. The default method is `GET` for
requests without a body, and `POST` for requests with a body.

## Usage

``` r
req_method(req, method)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- method:

  Custom HTTP method

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## Examples

``` r
request(example_url()) |> req_method("PATCH")
#> <httr2_request>
#> PATCH http://127.0.0.1:35099/
#> Body: empty
request(example_url()) |> req_method("PUT")
#> <httr2_request>
#> PUT http://127.0.0.1:35099/
#> Body: empty
request(example_url()) |> req_method("HEAD")
#> <httr2_request>
#> HEAD http://127.0.0.1:35099/
#> Body: empty
```
