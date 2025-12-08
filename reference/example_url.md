# Code for examples

`example_url()` runs a simple websever using the webfakes package with
the following endpoints:

- all the ones from the
  [`webfakes::httpbin_app()`](https://webfakes.r-lib.org/reference/httpbin_app.html)

- `/iris`: paginate through the iris dataset. It has the query
  parameters `page` and `limit` to control the pagination.

`example_github_client()` is an OAuth client for GitHub.

## Usage

``` r
example_url(path = "/")

example_github_client()
```
