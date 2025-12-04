# Perform a list of requests in parallel

This variation on
[`req_perform_sequential()`](https://httr2.r-lib.org/dev/reference/req_perform_sequential.md)
performs multiple requests in parallel. Never use it without
[`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md);
otherwise it's too easy to pummel a server with a very large number of
simultaneous requests.

While running, you'll get a progress bar that looks like:
`[working] (1 + 4) -> 5 -> 5`. The string tells you the current status
of the queue (e.g. working, waiting, errored) followed by (the number of
pending requests + pending retried requests) -\> the number of active
requests -\> the number of complete requests.

### Limitations

The main limitation of `req_perform_parallel()` is that it assumes
applies
[`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md)
and [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
are across all requests. This means, for example, that if request 1 is
throttled, but request 2 is not, `req_perform_parallel()` will wait for
request 1 before performing request 2. This makes it most suitable for
performing many parallel requests to the same host, rather than a mix of
different hosts. It's probably possible to remove these limitation, but
it's enough work that I'm unlikely to do it unless I know that people
would fine it useful: so please let me know!

Additionally, it does not respect the `max_tries` argument to
[`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md)
because if you have five requests in flight and the first one gets rate
limited, it's likely that all the others do too. This also means that
the circuit breaker is never triggered.

## Usage

``` r
req_perform_parallel(
  reqs,
  paths = NULL,
  on_error = c("stop", "return", "continue"),
  progress = TRUE,
  max_active = 10,
  mock = getOption("httr2_mock", NULL)
)
```

## Arguments

- reqs:

  A list of
  [request](https://httr2.r-lib.org/dev/reference/request.md)s.

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

- progress:

  Display a progress bar for the status of all requests? Use `TRUE` to
  turn on a basic progress bar, use a string to give it a name, or see
  [progress_bars](https://httr2.r-lib.org/dev/reference/progress_bars.md)
  to customize it in other ways. Not compatible with
  [`req_progress()`](https://httr2.r-lib.org/dev/reference/req_progress.md),
  as httr2 can only display a single progress bar at a time.

- max_active:

  Maximum number of concurrent requests.

- mock:

  A mocking function. If supplied, this function is called with the
  request. It should return either `NULL` (if it doesn't want to handle
  the request) or a
  [response](https://httr2.r-lib.org/dev/reference/response.md) (if it
  does). See
  [`with_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)/[`local_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  for more details.

## Value

A list, the same length as `reqs`, containing
[response](https://httr2.r-lib.org/dev/reference/response.md)s and
possibly error objects, if `on_error` is `"return"` or `"continue"` and
one of the responses errors. If `on_error` is `"return"` and it errors
on the ith request, the ith element of the result will be an error
object, and the remaining elements will be `NULL`. If `on_error` is
`"continue"`, it will be a mix of requests and error objects.

Only httr2 errors are captured; see
[`req_error()`](https://httr2.r-lib.org/dev/reference/req_error.md) for
more details.

## Examples

``` r
# Requesting these 4 pages one at a time would take 2 seconds:
request_base <- request(example_url()) |>
  req_throttle(capacity = 100, fill_time_s = 60)
reqs <- list(
  request_base |> req_url_path("/delay/0.5"),
  request_base |> req_url_path("/delay/0.5"),
  request_base |> req_url_path("/delay/0.5"),
  request_base |> req_url_path("/delay/0.5")
)
# But it's much faster if you request in parallel
system.time(resps <- req_perform_parallel(reqs))
#> [working] (0 + 0) -> 2 -> 2 | ■■■■■■■■■■■■■■■■                  50%
#> [working] (0 + 0) -> 0 -> 4 | ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  100%
#>    user  system elapsed 
#>   0.049   0.001   1.099 

# req_perform_parallel() will fail on error
reqs <- list(
  request_base |> req_url_path("/status/200"),
  request_base |> req_url_path("/status/400"),
  request("FAILURE")
)
try(resps <- req_perform_parallel(reqs))
#> Error in req_perform_parallel(reqs) : HTTP 400 Bad Request.

# but can use on_error to capture all successful results
resps <- req_perform_parallel(reqs, on_error = "continue")

# Inspect the successful responses
resps |> resps_successes()
#> [[1]]
#> <httr2_response>
#> GET http://127.0.0.1:39853/status/200
#> Status: 200 OK
#> Content-Type: text/plain
#> Body: None
#> 

# And the failed responses
resps |> resps_failures() |> resps_requests()
#> [[1]]
#> <httr2_request>
#> GET http://127.0.0.1:39853/status/400
#> Body: empty
#> Policies:
#> * throttle_realm: "127.0.0.1"
#> 
#> [[2]]
#> <httr2_request>
#> GET FAILURE
#> Body: empty
#> 
```
