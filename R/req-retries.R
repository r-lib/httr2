#' Control how and when a request will retry
#'
#' @description
#' There are two main cases in which a request might be retried:
#'
#' * The error occurs at the network layer and either the HTTP request or
#'   the response fails to complete successfully (e.g. because your wifi
#'   is down).
#'
#' * The error is "transient", i.e. it's an HTTP error that is likely to
#'   be resolve by waiting. By default httr2 will treat 429 and 503 statuses
#'   as transient. You can treat other responses as transient errors with
#'   the `is_transient` argument.
#'
#' httr2 uses two policies to determine how long to wait between requests:
#'
#' * If an HTTP error contains the `Retry-After` header, httr2 will either
#'   wait until the specified time or wait the specified number of seconds.
#'   You can consult a different header by using the `retry_after` argument.
#'
#' * Otherwise, httr2 will use "truncated exponential backoff with full
#'   jitter", to wait a random amount of time between one second and
#'   `2 ^ tries` seconds, capped to at most 60 seconds. In other words, it
#'   waits `runif(1, 2)` seconds after the first failure, then `runif(1, 4)`
#'   after the second. You can use a different algorithm by using the `backoff`
#'   argument.
#'
#' You can control the total number of requests by setting `max_tries`,
#' `max_seconds`, or both.
#'
#' @inheritParams req_fetch
#' @param max_tries,max_seconds Cap the maximum number of attempts with
#'  `max_tries` or the total elapsed time from the first request with
#'  `max_seconds`.
#' @param is_transient A predicate function that takes a single argument
#'   (the response) and returns `TRUE` or `FALSE` specifying whether or not
#'   the response represents a transient error (i.e. it should be retried
#'   after `backoff` seconds).
#' @param backoff A callback function that takes a single argument (the attempt
#'   number) and returns a single number giving the number of seconds to wait.
#' @param after A callback function that takes a single argument (the
#'   response) and returns either a number of seconds to wait or `NULL` (to
#'   indicate precise timing is not available and to instead use `backoff`).
#' @export
#' @examples
#' # google APIs assume that a 500 is also a transient error
#' req("http://google.com") %>%
#'   req_retry(is_transient = ~ resp_status(.x) %in% c(429, 500, 503))
#'
#' # use a constant 10s delay after every failure
#' req("http://example.com") %>%
#'   req_retry(backoff = ~ 10)
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

retry_after <- function(req, resp) {
  req_policy_call(req, "retry_after", list(resp), default = resp_retry_after)
}

# Helpers -----------------------------------------------------------------

# Exponential backoff with full-jitter, capped to 60s wait
# https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
backoff_default <- function(i) {
  min(stats::runif(1, 2^i), 60)
}

resp_retry_after <- function(resp) {
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After
  val <- resp_header(resp, "Retry-After")
  if (is.null(val)) {
    NULL
  } else if (grepl(" ", val)) {
    unclass(httr::parse_http_date(val)) - unix_time()
  } else {
    as.numeric(val)
  }
}
