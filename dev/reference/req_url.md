# Modify request URL

- `req_url()` replaces the entire URL.

- `req_url_relative()` navigates to a relative URL.

- `req_url_query()` modifies individual query components.

- `req_url_path()` modifies just the path.

- `req_url_path_append()` adds to the path.

## Usage

``` r
req_url(req, url)

req_url_relative(req, url)

req_url_query(
  .req,
  ...,
  .multi = c("error", "comma", "pipe", "explode"),
  .space = c("percent", "form")
)

req_url_path(req, ...)

req_url_path_append(req, ...)
```

## Arguments

- req, .req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- url:

  A new URL; either an absolute URL for `req_url()` or a relative URL
  for `req_url_relative()`.

- ...:

  For `req_url_query()`:
  \<[`dynamic-dots`](https://rlang.r-lib.org/reference/dyn-dots.html)\>
  Name-value pairs that define query parameters. Each value must be
  either an atomic vector or `NULL` (which removes the corresponding
  parameters). If you want to opt out of escaping, wrap strings in
  [`I()`](https://rdrr.io/r/base/AsIs.html).

  For `req_url_path()` and `req_url_path_append()`: A sequence of path
  components that will be combined with `/`.

- .multi:

  Controls what happens when a value is a vector:

  - `"error"`, the default, throws an error.

  - `"comma"`, separates values with a `,`, e.g. `?x=1,2`.

  - `"pipe"`, separates values with a `|`, e.g. `?x=1|2`.

  - `"explode"`, turns each element into its own parameter, e.g.
    `?x=1&x=2`

  If none of these options work for your needs, you can instead supply a
  function that takes a character vector of argument values and returns
  a a single string.

- .space:

  How should spaces in query params be escaped? The default, "percent",
  uses standard percent encoding (i.e. `%20`), but you can opt-in to
  "form" encoding, which uses `+` instead.

## Value

A modified HTTP
[request](https://httr2.r-lib.org/dev/reference/request.md).

## See also

- To modify a URL without creating a request, see
  [`url_modify()`](https://httr2.r-lib.org/dev/reference/url_modify.md)
  and friends.

- To use a template like `GET /user/{user}`, see
  [`req_template()`](https://httr2.r-lib.org/dev/reference/req_template.md).

## Examples

``` r
# Change complete url
req <- request("http://example.com")
req |> req_url("http://google.com")
#> <httr2_request>
#> GET http://google.com
#> Body: empty

# Use a relative url
req <- request("http://example.com/a/b/c")
req |> req_url_relative("..")
#> <httr2_request>
#> GET http://example.com/a/
#> Body: empty
req |> req_url_relative("/d/e/f")
#> <httr2_request>
#> GET http://example.com/d/e/f
#> Body: empty

# Change url components
req |>
  req_url_path_append("a") |>
  req_url_path_append("b") |>
  req_url_path_append("search.html") |>
  req_url_query(q = "the cool ice")
#> <httr2_request>
#> GET http://example.com/a/b/c/a/b/search.html?q=the%20cool%20ice
#> Body: empty

# Modify individual query parameters
req <- request("http://example.com?a=1&b=2")
req |> req_url_query(a = 10)
#> <httr2_request>
#> GET http://example.com/?b=2&a=10
#> Body: empty
req |> req_url_query(a = NULL)
#> <httr2_request>
#> GET http://example.com/?b=2
#> Body: empty
req |> req_url_query(c = 3)
#> <httr2_request>
#> GET http://example.com/?a=1&b=2&c=3
#> Body: empty

# Use .multi to control what happens with vector parameters:
req |> req_url_query(id = 100:105, .multi = "comma")
#> <httr2_request>
#> GET http://example.com/?a=1&b=2&id=100,101,102,103,104,105
#> Body: empty
req |> req_url_query(id = 100:105, .multi = "explode")
#> <httr2_request>
#> GET http://example.com/?a=1&b=2&id=100&id=101&id=102&id=103&id=104&id=105
#> Body: empty

# If you have query parameters in a list, use !!!
params <- list(a = "1", b = "2")
req |>
  req_url_query(!!!params, c = "3")
#> <httr2_request>
#> GET http://example.com/?a=1&b=2&c=3
#> Body: empty
```
