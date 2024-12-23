#' Automatically retry a request on failure
#'
#' @description
#' `req_retry()` allows [req_perform()] to automatically retry failing
#' requests. It's particularly important for APIs with rate limiting, but can
#' also be useful when dealing with flaky servers.
#'
#' By default, `req_perform()` will retry if the response is a 429
#' ("too many requests", often used for rate limiting) or 503
#' ("service unavailable"). If the API you are wrapping has other transient
#' status codes (or conveys transience with some other property of the
#' response), you can override the default with `is_transient`. And
#' if you set `retry_on_failure = TRUE`, the request will retry
#' if either the HTTP request or HTTP response doesn't complete successfully,
#' leading to an error from curl, the lower-level library that httr2 uses to
#' perform HTTP requests. This occurs, for example, if your Wi-Fi is down.
#'
#' ## Delay
#'
#' It's a bad idea to immediately retry a request, so `req_perform()` will
#' wait a little before trying again:
#'
#' * If the response contains the `Retry-After` header, httr2 will wait the
#'   amount of time it specifies. If the API you are wrapping conveys this
#'   information with a different header (or other property of the response),
#'   you can override the default behavior with `retry_after`.
#'
#' * Otherwise, httr2 will use "truncated exponential backoff with full
#'   jitter", i.e., it will wait a random amount of time between one second and
#'   `2 ^ tries` seconds, capped at a maximum of 60 seconds. In other words, it
#'   waits `runif(1, 1, 2)` seconds after the first failure, `runif(1, 1, 4)`
#'   after the second, `runif(1, 1, 8)` after the third, and so on. If you'd
#'   prefer a different strategy, you can override the default with `backoff`.
#'
#' @inheritParams req_perform
#' @param max_tries,max_seconds Cap the maximum number of attempts
#'   (`max_tries`), the total elapsed time from the first request
#'   (`max_seconds`), or both.
#'
#'   `max_tries` is the total number of attempts made, so this should always
#'   be greater than one.
#' @param is_transient A predicate function that takes a single argument
#'   (the response) and returns `TRUE` or `FALSE` specifying whether or not
#'   the response represents a transient error.
#' @param retry_on_failure Treat low-level failures as if they are
#'   transient errors that can be retried.
#' @param backoff A function that takes a single argument (the number of failed
#'   attempts so far) and returns the number of seconds to wait.
#' @param after A function that takes a single argument (the response) and
#'   returns either a number of seconds to wait or `NA`. `NA` indicates
#'   that a precise wait time is not available and that the `backoff` strategy
#'   should be used instead.
#' @param failure_threshold,failure_timeout,failure_realm
#'   Set `failure_threshold` to activate "circuit breaking" where if a request
#'   continues to fail after `failure_threshold` times, cause the request to
#'   error until a timeout of `failure_timeout` seconds has elapsed. This
#'   timeout will persist across all requests with the same `failure_realm`
#'   (which defaults to the hostname of the request) and is intended to detect
#'   failing servers without needing to wait each time.
#' @returns A modified HTTP [request].
#' @export
#' @seealso [req_throttle()] if the API has a rate-limit but doesn't expose
#'   the limits in the response.
#' @examples
#' # google APIs assume that a 500 is also a transient error
#' request("http://google.com") |>
#'   req_retry(is_transient = \(resp) resp_status(resp) %in% c(429, 500, 503))
#'
#' # use a constant 10s delay after every failure
#' request("http://example.com") |>
#'   req_retry(backoff = \(resp) 10)
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
#' request("http://api.github.com") |>
#'   req_retry(
#'     is_transient = github_is_transient,
#'     after = github_after
#'   )
req_retry <- function(req,
                      max_tries = NULL,
                      max_seconds = NULL,
                      retry_on_failure = FALSE,
                      is_transient = NULL,
                      backoff = NULL,
                      after = NULL,
                      failure_threshold = Inf,
                      failure_timeout = 30,
                      failure_realm = NULL) {

  check_request(req)
  check_number_whole(max_tries, min = 1, allow_null = TRUE)
  check_number_whole(max_seconds, min = 0, allow_null = TRUE)
  check_number_whole(failure_threshold, min = 1, allow_infinite = TRUE)
  check_number_whole(failure_timeout, min = 1)

  if (is.null(max_tries) && is.null(max_seconds)) {
    max_tries <- 2
    cli::cli_inform("Setting {.code max_tries = 2}.")
  }

  check_bool(retry_on_failure)

  req_policies(req,
    retry_max_tries = max_tries,
    retry_max_wait = max_seconds,
    retry_on_failure = retry_on_failure,
    retry_is_transient = as_callback(is_transient, 1, "is_transient"),
    retry_backoff = as_callback(backoff, 1, "backoff"),
    retry_after = as_callback(after, 1, "after"),
    retry_failure_threshold = failure_threshold,
    retry_failure_timeout = failure_timeout,
    retry_realm = failure_realm %||% url_parse(req$url)$hostname
  )
}

retry_max_tries <- function(req) {
  has_max_wait <- !is.null(req$policies$retry_max_wait)
  req$policies$retry_max_tries %||% if (has_max_wait) Inf else 1
}

retry_max_seconds <- function(req) {
  req$policies$retry_max_wait %||% Inf
}

retry_check_breaker <- function(req, i, error_call = caller_env()) {
  realm <- req$policies$retry_realm
  if (is.null(realm)) {
    return(invisible())
  }

  now <- unix_time()
  if (env_has(the$breaker, realm)) {
    triggered <- the$breaker[[realm]]
  } else if (i > req$policies$retry_failure_threshold) {
    the$breaker[[realm]] <- triggered <- now
  } else {
    return(invisible())
  }

  remaining <- req$policies$retry_failure_timeout - (now - triggered)
  if (remaining <= 0) {
    env_unbind(the$breaker, realm)
  } else {
    cli::cli_abort(
      c(
        "Too many request failures: circuit breaker triggered for realm {.str {realm}}.",
        i = "Wait {remaining} seconds before retrying."

      ),
      call = error_call,
      class = "httr2_breaker"
    )
  }
}

retry_is_transient <- function(req, resp) {
  if (is_error(resp)) {
    return(req$policies$retry_on_failure %||% FALSE)
  }

  req_policy_call(req, "retry_is_transient", list(resp),
    default = function(resp) resp_status(resp) %in% c(429, 503)
  )
}

retry_backoff <- function(req, i) {
  req_policy_call(req, "retry_backoff", list(i), default = backoff_default)
}

retry_after <- function(req, resp, i, error_call = caller_env()) {
  if (is_error(resp)) {
    return(retry_backoff(req, i))
  }

  after <- req_policy_call(req, "retry_after", list(resp), default = resp_retry_after)

  # TODO: apply this idea to all callbacks
  if (!is_number_or_na(after)) {
    not <- obj_type_friendly(after)
    cli::cli_abort(
      "The {.code after} callback to {.fn req_retry} must return a single number or NA, not {not}.",
      call = error_call
    )
  }

  if (is.na(after)) {
    retry_backoff(req, i)
  } else {
    after
  }
}

is_number_or_na <- function(x) {
  (is.numeric(x) && length(x) == 1) || identical(x, NA)
}

# Helpers -----------------------------------------------------------------

# Exponential backoff with full-jitter, capped to 60s wait
# https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
backoff_default <- function(i) {
  round(min(stats::runif(1, min = 1, max = 2^i), 60), 1)
}
