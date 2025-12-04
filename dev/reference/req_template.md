# Set request method/path from a template

Many APIs document their methods with a lightweight template mechanism
that looks like `GET /user/{user}` or `POST /organisation/:org`. This
function makes it easy to copy and paste such snippets and retrieve
template variables either from function arguments or the current
environment.

`req_template()` will append to the existing path so that you can set a
base url in the initial
[`request()`](https://httr2.r-lib.org/dev/reference/request.md). This
means that you'll generally want to avoid multiple `req_template()`
calls on the same request.

## Usage

``` r
req_template(req, template, ..., .env = parent.frame())
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- template:

  A template string which consists of a optional HTTP method and a path
  containing variables labelled like either `:foo` or `{foo}`.

- ...:

  Template variables.

- .env:

  Environment in which to look for template variables not found in
  `...`. Expert use only.

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## Examples

``` r
httpbin <- request(example_url())

# You can supply template parameters in `...`
httpbin |> req_template("GET /bytes/{n}", n = 100)
#> <httr2_request>
#> GET http://127.0.0.1:36377/bytes/100
#> Body: empty

# or you retrieve from the current environment
n <- 200
httpbin |> req_template("GET /bytes/{n}")
#> <httr2_request>
#> GET http://127.0.0.1:36377/bytes/200
#> Body: empty

# Existing path is preserved:
httpbin_test <- request(example_url()) |> req_url_path("/test")
name <- "id"
value <- "a3fWa"
httpbin_test |> req_template("GET /set/{name}/{value}")
#> <httr2_request>
#> GET http://127.0.0.1:36377/test/set/id/a3fWa
#> Body: empty
```
