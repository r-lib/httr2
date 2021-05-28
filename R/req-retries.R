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
#'   req_retry(is_transient = ~ resp_status_code(.x) %in% c(429, 500, 503))
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

  req$policies$retry_max_n <- req$policies$retry_max_n %||% max_tries
  req$policies$retry_max_wait <- req$policies$retry_max_wait %||% max_seconds
  if (!is.null(is_transient)) {
    req$policies$retry_is_transient <- as_function(is_transient)
  }
  if (!is.null(backoff)) {
    req$policies$retry_backoff <- as_function(backoff)
  }
  if (!is.null(after)) {
    req$policies$after <- as_function(after)
  }

  req
}

retry_max_tries <- function(req) {
  has_max_wait <- !is.null(req$policies$retries_max_wait)
  req$policies$retry_max_n %||% if (has_max_wait) Inf else 1
}

retry_deadline <- function(req) {
  Sys.time() + (req$policies$retries_max_wait %||% Inf)
}

retry_is_transient <- function(req, resp) {
  if (req_has_policy(req, "retry_is_transient")) {
    isTRUE(req$policies$retry_is_transient(resp))
  } else {
    FALSE
  }
}

retry_backoff <- function(req, i) {
  if (req_has_policy(req, "retry_backoff")) {
    req$policies$retry_backoff(i)
  } else {
    # Exponential backoff with full-jitter, capped to 60s wait
    # https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
    min(stats::runif(1, 2^i), 60)
  }
}

retry_after <- function(req, resp) {
  if (req_has_policy(req, "retry_after")) {
    return(req$policies$retry_after(resp))
  }

  if (!resp_header_exists(resp, "Rate-Limit")) {
    return(NULL)
  }

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After
  val <- resp_header(resp, "Retry-After")
  if (grepl(" ", val)) {
    unclass(httr::parse_http_date(val)) - unclass(Sys.time())
  } else {
    as.numeric(val)
  }
}
