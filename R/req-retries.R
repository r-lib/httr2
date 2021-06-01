#' Control when a request will retry, and how long it will wait between tries
#'
#' @description
#' `req_retry()` alters [req_fetch()] so that it will automatically retry
#' in the case of failure. To activate it, you must specify either the total
#' number of requests to make with `max_tries` or the total amount of time
#' to spend with `max_seconds`. Then `req_fetch()` will retry if:
#'
#' * The either the HTTP request or HTTP response doesn't complete successfully
#'   leading to an error from curl, the lower-level library that httr uses to
#'   perform HTTP request. This occurs, for example, if your wifi is down.
#'
#' * The error is "transient", i.e. it's an HTTP error that can be resolved
#'   by waiting. By default, 429 and 503 statuses are treated as transient,
#'   but if the API you are wrapping has other transient status codes (or
#'   conveys transient-ness with some other property of the response), you can
#'   override the default with `is_transient`.
#'
#' It's a bad idea to immediately retry a request, so `req_fetch()` will
#' wait a little before trying again:
#'
#' * If the response contains the `Retry-After` header, httr2 will wait the
#'   amount of time it specifies. If the API you are wrapping conveys this
#'   information with a different header (or other property of the response)
#'   you can override the default behaviour with `retry_after`.
#'
#' * Otherwise, httr2 will use "truncated exponential backoff with full
#'   jitter", i.e. it will wait a random amount of time between one second and
#'   `2 ^ tries` seconds, capped to at most 60 seconds. In other words, it
#'   waits `runif(1, 1, 2)` seconds after the first failure, `runif(1, 1, 4)`
#'   after the second, `runif(1, 1, 8)` after the third, and so on. If you'd
#'   prefer a different strategy, you can override the default with `backoff`.
#'
#' @inheritParams req_fetch
#' @param max_tries,max_seconds Cap the maximum number of attempts with
#'  `max_tries` or the total elapsed time from the first request with
#'  `max_seconds`. If neither option is supplied (the default), [req_fetch()]
#'  will not retry.
#' @param is_transient A predicate function that takes a single argument
#'   (the response) and returns `TRUE` or `FALSE` specifying whether or not
#'   the response represents a transient error.
#' @param backoff A function that takes a single argument (the number of failed
#'   attempts so far) and returns the number of seconds to wait.
#' @param after A function that takes a single argument (the response) and
#'   returns either a number of seconds to wait or `NULL`, which indicates
#'   that a precise wait time is not available that the `backoff` strategy
#'   should be used instead..
#' @export
#' @examples
#' # google APIs assume that a 500 is also a transient error
#' req("http://google.com") %>%
#'   req_retry(is_transient = ~ resp_status(.x) %in% c(429, 500, 503))
#'
#' # use a constant 10s delay after every failure
#' req("http://example.com") %>%
#'   req_retry(backoff = ~ 10)
#'
#' # When rate-limited, GitHub's API returns a 403 with
#' # `X-RateLimit-Remaining: 0` and an Unix time stored in the
#' # `X-RateLimit-Reset` header. This takes a bit more work to handle:
#' github_is_transient <- function(resp) {
#'   resp_status(resp) == 403 &&
#'     identical(resp_header(resp, "X-RateLimit-Remaining"), "0")
#' }
#' github_after <- function(resp) {
#'   time <- as.numeric(resp_header(resp, "X-RateLimit-Reset"))
#'   time - unclass(Sys.time())
#' }
#' req("http://api.github.com") %>%
#'   req_retry(
#'     is_transient = github_is_transient,
#'     after = github_after
#'   )
req_retry <- function(req,
                      max_tries = NULL,
                      max_seconds = NULL,
                      is_transient = NULL,
                      backoff = NULL,
                      after = NULL) {
  check_request(req)

  req_policies(req,
    retry_max_tries = max_tries,
    retry_max_wait = max_seconds,
    retry_is_transient = as_callback(is_transient, 1, "is_transient"),
    retry_backoff = as_callback(backoff, 1, "backoff"),
    retry_after = as_callback(after, 1, "after")
  )
}

retry_max_tries <- function(req) {
  has_max_wait <- !is.null(req$policies$retry_max_wait)
  req$policies$retry_max_tries %||% if (has_max_wait) Inf else 1
}

retry_max_seconds <- function(req) {
  req$policies$retry_max_wait %||% Inf
}

retry_is_transient <- function(req, resp) {
  req_policy_call(req, "retry_is_transient", list(resp),
    default = function(resp) resp_status(resp) %in% c(429, 503)
  )
}

retry_backoff <- function(req, i) {
  req_policy_call(req, "retry_backoff", list(i), default = backoff_default)
}

retry_after <- function(req, resp, i) {
  after <- req_policy_call(req, "retry_after", list(resp), default = resp_retry_after)
  after %||% retry_backoff(req, i)
}

# Helpers -----------------------------------------------------------------

# Exponential backoff with full-jitter, capped to 60s wait
# https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
backoff_default <- function(i) {
  round(min(stats::runif(1, min = 1, max = 2^i), 60), 1)
}
