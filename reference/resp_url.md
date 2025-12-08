# Get URL/components from the response

- `resp_url()` returns the complete url.

- `resp_url_path()` returns the path component.

- `resp_url_query()` returns a single query component.

- `resp_url_queries()` returns the query component as a named list.

## Usage

``` r
resp_url(resp)

resp_url_path(resp)

resp_url_query(resp, name, default = NULL)

resp_url_queries(resp)
```

## Arguments

- resp:

  A httr2 [response](https://httr2.r-lib.org/reference/response.md)
  object, created by
  [`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md).

- name:

  Query parameter name.

- default:

  Default value to use if query parameter doesn't exist.

## Examples

``` r
resp <- request(example_url()) |>
  req_url_path("/get") |>
  req_url_query(hello = "world") |>
  req_perform()

resp |> resp_url()
#> [1] "http://127.0.0.1:41151/get?hello=world"
resp |> resp_url_path()
#> [1] "/get"
resp |> resp_url_queries()
#> $hello
#> [1] "world"
#> 
resp |> resp_url_query("hello")
#> [1] "world"
```
