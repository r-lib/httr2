# Perform request asynchronously using the promises package

**\[experimental\]**

This variation on
[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md)
returns a
[`promises::promise()`](https://rstudio.github.io/promises/reference/promise.html)
object immediately and then performs the request in the background,
returning program control before the request is finished. See the
[promises package
documentation](https://rstudio.github.io/promises/articles/promises_01_motivation.html)
for more details on how to work with the resulting promise object.

If using together with
[`later::with_temp_loop()`](https://later.r-lib.org/reference/create_loop.html)
or other private event loops, a new curl pool made by
[`curl::new_pool()`](https://jeroen.r-universe.dev/curl/reference/multi.html)
should be created for requests made within the loop to ensure that only
these requests are being polled by the loop.

Like with
[`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md),
exercise caution when using this function; it's easy to pummel a server
with many simultaneous requests. Also, not all servers can handle more
than 1 request at a time, so the responses may still return
sequentially.

`req_perform_promise()` also has similar limitations to the
[`req_perform_parallel()`](https://httr2.r-lib.org/dev/reference/req_perform_parallel.md)
function, it:

- Will not retrieve a new OAuth token if it expires after the promised
  request is created but before it is actually requested.

- Does not perform throttling with
  [`req_throttle()`](https://httr2.r-lib.org/dev/reference/req_throttle.md).

- Does not attempt retries as described by
  [`req_retry()`](https://httr2.r-lib.org/dev/reference/req_retry.md).

- Only consults the cache set by
  [`req_cache()`](https://httr2.r-lib.org/dev/reference/req_cache.md)
  when the request is promised.

## Usage

``` r
req_perform_promise(
  req,
  path = NULL,
  pool = NULL,
  verbosity = NULL,
  mock = getOption("httr2_mock", NULL)
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/dev/reference/request.md)
  object.

- path:

  Optionally, path to save body of the response. This is useful for
  large responses since it avoids storing the response in memory.

- pool:

  A pool created by
  [`curl::new_pool()`](https://jeroen.r-universe.dev/curl/reference/multi.html).

- verbosity:

  How much information to print? This is a wrapper around
  [`req_verbose()`](https://httr2.r-lib.org/dev/reference/req_verbose.md)
  that uses an integer to control verbosity:

  - `0`: no output

  - `1`: show headers

  - `2`: show headers and bodies

  - `3`: show headers, bodies, and curl status messages.

  Use
  [`with_verbosity()`](https://httr2.r-lib.org/dev/reference/with_verbosity.md)
  to control the verbosity of requests that you can't affect directly.

- mock:

  A mocking function. If supplied, this function is called with the
  request. It should return either `NULL` (if it doesn't want to handle
  the request) or a
  [response](https://httr2.r-lib.org/dev/reference/response.md) (if it
  does). See
  [`with_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)/[`local_mocked_responses()`](https://httr2.r-lib.org/dev/reference/with_mocked_responses.md)
  for more details.

## Value

a
[`promises::promise()`](https://rstudio.github.io/promises/reference/promise.html)
object which resolves to a
[response](https://httr2.r-lib.org/dev/reference/response.md) if
successful or rejects on the same errors thrown by
[`req_perform()`](https://httr2.r-lib.org/dev/reference/req_perform.md).

## Examples

``` r
if (FALSE) { # \dontrun{
library(promises)
request_base <- request(example_url()) |> req_url_path_append("delay")

p <- request_base |> req_url_path_append(2) |> req_perform_promise()

# A promise object, not particularly useful on its own
p

# Use promise chaining functions to access results
p %...>%
  resp_body_json() %...>%
  print()


# Can run two requests at the same time
p1 <- request_base |> req_url_path_append(2) |> req_perform_promise()
p2 <- request_base |> req_url_path_append(1) |> req_perform_promise()

p1 %...>%
  resp_url_path %...>%
  paste0(., " finished") %...>%
  print()

p2 %...>%
  resp_url_path %...>%
  paste0(., " finished") %...>%
  print()

# See the [promises package documentation](https://rstudio.github.io/promises/)
# for more information on working with promises
} # }
```
