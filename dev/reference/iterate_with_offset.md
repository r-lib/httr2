# Iteration helpers

These functions are intended for use with the `next_req` argument to
[`req_perform_iterative()`](https://httr2.r-lib.org/dev/reference/req_perform_iterative.md).
Each implements iteration for a common pagination pattern:

- `iterate_with_offset()` increments a query parameter, e.g. `?page=1`,
  `?page=2`, or `?offset=1`, `offset=21`.

- `iterate_with_cursor()` updates a query parameter with the value of a
  cursor found somewhere in the response.

- `iterate_with_link_url()` follows the url found in the `Link` header.
  See
  [`resp_link_url()`](https://httr2.r-lib.org/dev/reference/resp_link_url.md)
  for more details.

## Usage

``` r
iterate_with_offset(
  param_name,
  start = 1,
  offset = 1,
  resp_pages = NULL,
  resp_complete = NULL
)

iterate_with_cursor(param_name, resp_param_value)

iterate_with_link_url(rel = "next")
```

## Arguments

- param_name:

  Name of query parameter.

- start:

  Starting value.

- offset:

  Offset for each page. The default is set to `1` so you get (e.g.)
  `?page=1`, `?page=2`, ... If `param_name` refers to an element index
  (rather than a page index) you'll want to set this to a larger number
  so you get (e.g.) `?items=20`, `?items=40`, ...

- resp_pages:

  A callback function that takes a response (`resp`) and returns the
  total number of pages, or `NULL` if unknown. It will only be called
  once.

- resp_complete:

  A callback function that takes a response (`resp`) and returns `TRUE`
  if there are no further pages.

- resp_param_value:

  A callback function that takes a response (`resp`) and returns the
  next cursor value. Return `NULL` if there are no further pages.

- rel:

  The "link relation type" to use to retrieve the next page.

## Examples

``` r
req <- request(example_url()) |>
  req_url_path("/iris") |>
  req_throttle(10) |>
  req_url_query(limit = 50)

# If you don't know the total number of pages in advance, you can
# provide a `resp_complete()` callback
is_complete <- function(resp) {
  length(resp_body_json(resp)$data) == 0
}
resps <- req_perform_iterative(
  req,
  next_req = iterate_with_offset("page_index", resp_complete = is_complete),
  max_reqs = Inf
)

if (FALSE) { # \dontrun{
# Alternatively, if the response returns the total number of pages (or you
# can easily calculate it), you can use the `resp_pages()` callback which
# will generate a better progress bar.

resps <- req_perform_iterative(
  req |> req_url_query(limit = 1),
  next_req = iterate_with_offset(
    "page_index",
    resp_pages = function(resp) resp_body_json(resp)$pages
  ),
  max_reqs = Inf
)
} # }
```
