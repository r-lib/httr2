# Perform requests iteratively, generating new requests from previous responses

`req_perform_iterative()` iteratively generates and performs requests,
using a callback function, `next_req`, to define the next request based
on the current request and response. You will probably want to pair it
with an [iteration
helper](https://httr2.r-lib.org/reference/iterate_with_offset.md) and
use a [multi-response
handler](https://httr2.r-lib.org/reference/resps_successes.md) to
process the result.

## Usage

``` r
req_perform_iterative(
  req,
  next_req,
  path = NULL,
  max_reqs = 20,
  on_error = c("stop", "return"),
  mock = getOption("httr2_mock", NULL),
  progress = TRUE
)
```

## Arguments

- req:

  The first [request](https://httr2.r-lib.org/reference/request.md) to
  perform.

- next_req:

  A function that takes the previous response (`resp`) and request
  (`req`) and returns a
  [request](https://httr2.r-lib.org/reference/request.md) for the next
  page or `NULL` if the iteration should terminate. See below for more
  details.

- path:

  Optionally, path to save the body of request. This should be a glue
  string that uses `{i}` to distinguish different requests. Useful for
  large responses because it avoids storing the response in memory.

- max_reqs:

  The maximum number of requests to perform. Use `Inf` to perform all
  requests until `next_req()` returns `NULL`.

- on_error:

  What should happen if a request fails?

  - `"stop"`, the default: stop iterating with an error.

  - `"return"`: stop iterating, returning all the successful responses
    so far, as well as an error object for the failed request.

- mock:

  A mocking function. If supplied, this function is called with the
  request. It should return either `NULL` (if it doesn't want to handle
  the request) or a
  [response](https://httr2.r-lib.org/reference/response.md) (if it
  does). See
  [`with_mocked_responses()`](https://httr2.r-lib.org/reference/with_mocked_responses.md)/[`local_mocked_responses()`](https://httr2.r-lib.org/reference/with_mocked_responses.md)
  for more details.

- progress:

  Display a progress bar for the status of all requests? Use `TRUE` to
  turn on a basic progress bar, use a string to give it a name, or see
  [progress_bars](https://httr2.r-lib.org/reference/progress_bars.md) to
  customize it in other ways. Not compatible with
  [`req_progress()`](https://httr2.r-lib.org/reference/req_progress.md),
  as httr2 can only display a single progress bar at a time.

## Value

A list, at most length `max_reqs`, containing
[response](https://httr2.r-lib.org/reference/response.md)s and possibly
one error object, if `on_error` is `"return"` and one of the requests
errors. If present, the error object will always be the last element in
the list.

Only httr2 errors are captured; see
[`req_error()`](https://httr2.r-lib.org/reference/req_error.md) for more
details.

## `next_req()`

The key piece that makes `req_perform_iterative()` work is the
`next_req()` argument. For most common cases, you can use one of the
canned helpers, like
[`iterate_with_offset()`](https://httr2.r-lib.org/reference/iterate_with_offset.md).
If, however, the API you're wrapping uses a different pagination system,
you'll need to write your own. This section gives some advice.

Generally, your function needs to inspect the response, extract some
data from it, then use that to modify the previous request. For example,
imagine that the response returns a cursor, which needs to be added to
the body of the request. The simplest version of this function might
look like this:

    next_req <- function(resp, req) {
      cursor <- resp_body_json(resp)$next_cursor
      req |> req_body_json_modify(cursor = cursor)
    }

There's one problem here: if there are no more pages to return, then
`cursor` will be `NULL`, but
[`req_body_json_modify()`](https://httr2.r-lib.org/reference/req_body.md)
will still generate a meaningful request. So we need to handle this
specifically by returning `NULL`:

    next_req <- function(resp, req) {
      cursor <- resp_body_json(resp)$next_cursor
      if (is.null(cursor))
        return(NULL)
      req |> req_body_json_modify(cursor = cursor)
    }

A value of `NULL` lets `req_perform_iterative()` know there are no more
pages remaining.

There's one last feature you might want to add to your iterator: if you
know the total number of pages, then it's nice to let
`req_perform_iterative()` know so it can adjust the progress bar. (This
will only ever decrease the number of pages, not increase it.) You can
signal the total number of pages by calling
[`signal_total_pages()`](https://httr2.r-lib.org/reference/signal_total_pages.md),
like this:

    next_req <- function(resp, req) {
      body <- resp_body_json(resp)
      cursor <- body$next_cursor
      if (is.null(cursor))
        return(NULL)

      signal_total_pages(body$pages)
      req |> req_body_json_modify(cursor = cursor)
    }

## Examples

``` r
req <- request(example_url()) |>
  req_url_path("/iris") |>
  req_throttle(10) |>
  req_url_query(limit = 5)

resps <- req_perform_iterative(req, iterate_with_offset("page_index"))

data <- resps |> resps_data(function(resp) {
  data <- resp_body_json(resp)$data
  data.frame(
    Sepal.Length = sapply(data, `[[`, "Sepal.Length"),
    Sepal.Width = sapply(data, `[[`, "Sepal.Width"),
    Petal.Length = sapply(data, `[[`, "Petal.Length"),
    Petal.Width = sapply(data, `[[`, "Petal.Width"),
    Species = sapply(data, `[[`, "Species")
  )
})
str(data)
#> 'data.frame':    100 obs. of  5 variables:
#>  $ Sepal.Length: num  5.1 4.9 4.7 4.6 5 5.4 4.6 5 4.4 4.9 ...
#>  $ Sepal.Width : num  3.5 3 3.2 3.1 3.6 3.9 3.4 3.4 2.9 3.1 ...
#>  $ Petal.Length: num  1.4 1.4 1.3 1.5 1.4 1.7 1.4 1.5 1.4 1.5 ...
#>  $ Petal.Width : num  0.2 0.2 0.2 0.2 0.2 0.4 0.3 0.2 0.2 0.1 ...
#>  $ Species     : chr  "setosa" "setosa" "setosa" "setosa" ...
```
