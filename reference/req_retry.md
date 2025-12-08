# Automatically retry a request on failure

`req_retry()` allows
[`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md) to
automatically retry failing requests. It's particularly important for
APIs with rate limiting, but can also be useful when dealing with flaky
servers.

By default,
[`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md) will
retry if the response is a 429 ("too many requests", often used for rate
limiting) or 503 ("service unavailable"). If the API you are wrapping
has other transient status codes (or conveys transience with some other
property of the response), you can override the default with
`is_transient`. And if you set `retry_on_failure = TRUE`, the request
will retry if either the HTTP request or HTTP response doesn't complete
successfully, leading to an error from curl, the lower-level library
that httr2 uses to perform HTTP requests. This occurs, for example, if
your Wi-Fi is down.

### Delay

It's a bad idea to immediately retry a request, so
[`req_perform()`](https://httr2.r-lib.org/reference/req_perform.md) will
wait a little before trying again:

- If the response contains the `Retry-After` header, httr2 will wait the
  amount of time it specifies. If the API you are wrapping conveys this
  information with a different header (or other property of the
  response), you can override the default behavior with `retry_after`.

- Otherwise, httr2 will use "truncated exponential backoff with full
  jitter", i.e., it will wait a random amount of time between one second
  and `2 ^ tries` seconds, capped at a maximum of 60 seconds. In other
  words, it waits `runif(1, 1, 2)` seconds after the first failure,
  `runif(1, 1, 4)` after the second, `runif(1, 1, 8)` after the third,
  and so on. If you'd prefer a different strategy, you can override the
  default with `backoff`.

## Usage

``` r
req_retry(
  req,
  max_tries = NULL,
  max_seconds = NULL,
  retry_on_failure = FALSE,
  is_transient = NULL,
  backoff = NULL,
  after = NULL,
  failure_threshold = Inf,
  failure_timeout = 30,
  failure_realm = NULL
)
```

## Arguments

- req:

  A httr2 [request](https://httr2.r-lib.org/reference/request.md)
  object.

- max_tries, max_seconds:

  Cap the maximum number of attempts (`max_tries`), the total elapsed
  time from the first request (`max_seconds`), or both.

  `max_tries` is the total number of attempts made, so this should
  always be greater than one.

- retry_on_failure:

  Treat low-level failures as if they are transient errors that can be
  retried.

- is_transient:

  A predicate function that takes a single argument (the response) and
  returns `TRUE` or `FALSE` specifying whether or not the response
  represents a transient error.

- backoff:

  A function that takes a single argument (the number of failed attempts
  so far) and returns the number of seconds to wait.

- after:

  A function that takes a single argument (the response) and returns
  either a number of seconds to wait or `NA`. `NA` indicates that a
  precise wait time is not available and that the `backoff` strategy
  should be used instead.

- failure_threshold, failure_timeout, failure_realm:

  Set `failure_threshold` to activate "circuit breaking" where if a
  request continues to fail after `failure_threshold` times, cause the
  request to error until a timeout of `failure_timeout` seconds has
  elapsed. This timeout will persist across all requests with the same
  `failure_realm` (which defaults to the hostname of the request) and is
  intended to detect failing servers without needing to wait each time.

## Value

A modified HTTP [request](https://httr2.r-lib.org/reference/request.md).

## See also

[`req_throttle()`](https://httr2.r-lib.org/reference/req_throttle.md) if
the API has a rate-limit but doesn't expose the limits in the response.

## Examples

``` r
# google APIs assume that a 500 is also a transient error
request("http://google.com") |>
  req_retry(is_transient = \(resp) resp_status(resp) %in% c(429, 500, 503))
#> Setting `max_tries = 2`.
#> <httr2_request>
#> GET http://google.com
#> Body: empty
#> Policies:
#> * retry_max_tries        : 2
#> * retry_on_failure       : FALSE
#> * retry_is_transient     : <function>
#> * retry_failure_threshold: Inf
#> * retry_failure_timeout  : 30
#> * retry_realm            : "google.com"

# use a constant 10s delay after every failure
request("http://example.com") |>
  req_retry(backoff = \(resp) 10)
#> Setting `max_tries = 2`.
#> <httr2_request>
#> GET http://example.com
#> Body: empty
#> Policies:
#> * retry_max_tries        : 2
#> * retry_on_failure       : FALSE
#> * retry_backoff          : <function>
#> * retry_failure_threshold: Inf
#> * retry_failure_timeout  : 30
#> * retry_realm            : "example.com"

# When rate-limited, GitHub's API returns a 403 with
# `X-RateLimit-Remaining: 0` and an Unix time stored in the
# `X-RateLimit-Reset` header. This takes a bit more work to handle:
github_is_transient <- function(resp) {
  resp_status(resp) == 403 &&
    identical(resp_header(resp, "X-RateLimit-Remaining"), "0")
}
github_after <- function(resp) {
  time <- as.numeric(resp_header(resp, "X-RateLimit-Reset"))
  time - unclass(Sys.time())
}
request("http://api.github.com") |>
  req_retry(
    is_transient = github_is_transient,
    after = github_after
  )
#> Setting `max_tries = 2`.
#> <httr2_request>
#> GET http://api.github.com
#> Body: empty
#> Policies:
#> * retry_max_tries        : 2
#> * retry_on_failure       : FALSE
#> * retry_is_transient     : <function>
#> * retry_after            : <function>
#> * retry_failure_threshold: Inf
#> * retry_failure_timeout  : 30
#> * retry_realm            : "api.github.com"
```
