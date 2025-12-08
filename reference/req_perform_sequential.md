# Perform multiple requests in sequence

Given a list of requests, this function performs each in turn, returning
a list of responses. It's the serial equivalent of
[`req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.md).

## Usage

``` r
req_perform_sequential(
  reqs,
  paths = NULL,
  on_error = c("stop", "return", "continue"),
  mock = getOption("httr2_mock", NULL),
  progress = TRUE
)
```

## Arguments

- reqs:

  A list of [request](https://httr2.r-lib.org/reference/request.md)s.

- paths:

  An optional character vector of paths, if you want to download the
  response bodies to disk. If supplied, must be the same length as
  `reqs`.

- on_error:

  What should happen if one of the requests fails?

  - `stop`, the default: stop iterating with an error.

  - `return`: stop iterating, returning all the successful responses
    received so far, as well as an error object for the failed request.

  - `continue`: continue iterating, recording errors in the result.

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

A list, the same length as `reqs`, containing
[response](https://httr2.r-lib.org/reference/response.md)s and possibly
error objects, if `on_error` is `"return"` or `"continue"` and one of
the responses errors. If `on_error` is `"return"` and it errors on the
ith request, the ith element of the result will be an error object, and
the remaining elements will be `NULL`. If `on_error` is `"continue"`, it
will be a mix of requests and error objects.

Only httr2 errors are captured; see
[`req_error()`](https://httr2.r-lib.org/reference/req_error.md) for more
details.

## Examples

``` r
# One use of req_perform_sequential() is if the API allows you to request
# data for multiple objects, you want data for more objects than can fit
# in one request.
req <- request("https://api.restful-api.dev/objects")

# Imagine we have 50 ids:
ids <- sort(sample(100, 50))

# But the API only allows us to request 10 at time. So we first use split
# and some modulo arithmetic magic to generate chunks of length 10
chunks <- unname(split(ids, (seq_along(ids) - 1) %/% 10))

# Then we use lapply to generate one request for each chunk:
reqs <- chunks |> lapply(\(idx) req |> req_url_query(id = idx, .multi = "comma"))

# Then we can perform them all and get the results
if (FALSE) { # \dontrun{
resps <- reqs |> req_perform_sequential()
resps_data(resps, \(resp) resp_body_json(resp))
} # }
```
