#' Rate limit a request by automatically adding a delay
#'
#' @description
#' Use `req_throttle()` to ensure that repeated calls to [req_perform()] never
#' exceed a specified rate.
#'
#' Throttling is implemented using a "token bucket", which steadily fills up to
#' a maximum of `capacity` tokens over `fill_time_s`. Each time you make a
#' request, it takes a token out of the bucket, and if the bucket is empty,
#' the request will wait until the bucket refills. This ensures that you never
#' make more than `capacity` requests in `fill_time_s`, but you can make
#' requests more quickly if the bucket is full. For example, if you have
#' `capacity = 10` and `fill_time_s = 60`, you can make 10 requests
#' without waiting, but the next request will wait 60 seconds. This gives the
#' same average throttling rate as the previous approach, but gives you much
#' better performance if you're only making a small number of requests.
#'
#' Some APIs enforce multiple rate limits simultaneously, e.g. no more than
#' 4 requests per second *and* no more than 200 requests per hour. You can
#' handle this by supplying a vector to `capacity` and `fill_time_s`: this
#' creates one token bucket per limit, and each request must satisfy all of
#' them. This lets you make quick bursts of requests while still respecting
#' longer term limits.
#'
#' @inheritParams req_perform
#' @param capacity The size of the bucket, i.e. the maximum number of
#'   tokens that can accumulate. To enforce multiple rate limits at once,
#'   supply a vector of capacities (one per limit); `capacity` and
#'   `fill_time_s` are recycled to a common length.
#' @param rate For backwards compatibility, you can still specify the `rate`,
#'   which is converted to `capacity` by multiplying by `fill_time_s`.
#'   However, we recommend using `capacity` and `fill_time_s` as it gives more
#'   control.
#' @param fill_time_s Time in seconds to fill the capacity. Defaults to 60s.
#' @param realm A string that uniquely identifies the throttle pool to use
#'   (throttling limits always apply *per pool*). If not supplied, defaults
#'   to the hostname of the request.
#' @returns A modified HTTP [request].
#' @seealso [req_retry()] for another way of handling rate-limited APIs.
#' @export
#' @examples
#' # Ensure we never send more than 30 requests a minute
#' req <- request(example_url()) |>
#'   req_throttle(capacity = 30, fill_time_s = 60)
#'
#' resp <- req_perform(req)
#' throttle_status()
#' resp <- req_perform(req)
#' throttle_status()
#' \dontshow{httr2:::throttle_reset()}
#'
#' # Enforce multiple limits at once: no more than 10 requests every 1s
#' # and no more than 100 requests every 60s
#' req <- request(example_url()) |>
#'   req_throttle(capacity = c(10, 100), fill_time_s = c(1, 60))
#' resp <- req_perform(req)
#' throttle_status()
#' \dontshow{httr2:::throttle_reset()}
req_throttle <- function(req, rate, capacity, fill_time_s = 60, realm = NULL) {
  check_request(req)
  check_exclusive(rate, capacity)
  check_throttle_number(fill_time_s)
  check_string(realm, allow_null = TRUE)

  if (missing(capacity)) {
    check_throttle_number(rate)
    args <- vctrs::vec_recycle_common(rate = rate, fill_time_s = fill_time_s)
    capacity <- args$rate * args$fill_time_s
  } else {
    check_throttle_number(capacity, whole = TRUE)
    args <- vctrs::vec_recycle_common(
      capacity = capacity,
      fill_time_s = fill_time_s
    )
    capacity <- args$capacity
  }
  fill_rate <- capacity / args$fill_time_s

  realm <- realm %||% url_parse(req$url)$hostname
  if (!throttle_exists(realm, capacity, fill_rate)) {
    the$throttle[[realm]] <- map2(
      capacity,
      fill_rate,
      function(capacity, fill_rate) TokenBucket$new(capacity, fill_rate)
    )
  }
  req_policies(req, throttle_realm = realm)
}

# Validates a non-negative numeric vector of throttle parameters.
check_throttle_number <- function(
  x,
  whole = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
  if (missing(x) || !is.numeric(x) || length(x) == 0 || anyNA(x)) {
    stop_input_type(x, "a numeric vector", arg = arg, call = call)
  }
  if (any(x < 0)) {
    cli::cli_abort(
      "Every element of {.arg {arg}} must be 0 or greater.",
      call = call
    )
  }
  if (whole && any(x != trunc(x))) {
    cli::cli_abort(
      "Every element of {.arg {arg}} must be a whole number.",
      call = call
    )
  }
  invisible()
}

#' Display internal throttle status
#'
#' Sometimes useful for debugging.
#'
#' @return A data frame with one row per token bucket and four columns:
#'   * The `realm`.
#'   * The `capacity` of the bucket.
#'   * Number of `tokens` remaining in the bucket.
#'   * Time `to_wait` in seconds for next token.
#' @export
#' @keywords internal
throttle_status <- function() {
  # Trigger refill before displaying status
  walk(the$throttle, function(buckets) walk(buckets, function(b) b$refill()))

  realm <- character()
  capacity <- tokens <- to_wait <- double()
  # Just for debugging so focus on simplicity rather than efficiency
  for (r in sort(env_names(the$throttle))) {
    buckets <- the$throttle[[r]]
    realm <- c(realm, rep(r, length(buckets)))
    capacity <- c(capacity, map_dbl(buckets, function(b) b$capacity))
    tokens <- c(tokens, floor(map_dbl(buckets, function(b) b$tokens)))
    to_wait <- c(to_wait, map_dbl(buckets, function(b) b$token_wait_time()))
  }

  data.frame(
    realm = realm,
    capacity = capacity,
    tokens = tokens,
    to_wait = to_wait,
    row.names = NULL,
    check.names = FALSE
  )
}

throttle_reset <- function(realm = NULL) {
  if (is.null(realm)) {
    the$throttle <- new_environment()
  } else {
    env_unbind(the$throttle, realm)
  }

  invisible()
}

throttle_exists <- function(realm, capacity, fill_rate) {
  if (!env_has(the$throttle, realm)) {
    return(FALSE)
  }

  buckets <- the$throttle[[realm]]
  length(buckets) == length(capacity) &&
    all(map_dbl(buckets, \(b) b$capacity) == capacity) &&
    all(map_dbl(buckets, \(b) b$fill_rate) == fill_rate)
}

throttle_delay <- function(req) {
  if (!req_policy_exists(req, "throttle_realm")) {
    0
  } else {
    # Each request takes a token from every bucket, but only needs to wait
    # for the slowest one to refill.
    buckets <- the$throttle[[req$policies$throttle_realm]]
    max(map_dbl(buckets, \(b) b$take_token()))
  }
}
throttle_deadline <- function(req) {
  unix_time() + throttle_delay(req)
}
throttle_return_token <- function(req) {
  buckets <- the$throttle[[req$policies$throttle_realm]]
  walk(buckets, \(b) b$return_token())
}

TokenBucket <- R6::R6Class(
  "TokenBucket",
  public = list(
    capacity = NULL,
    fill_rate = NULL,

    last_fill = NULL,
    tokens = NULL,

    initialize = function(capacity, fill_rate) {
      self$capacity <- capacity
      self$tokens <- capacity
      self$fill_rate <- fill_rate

      self$last_fill <- unix_time()
    },

    refill = function() {
      now <- unix_time()
      # Ensure if we call rapidly we don't accumulate FP errors
      if (now - self$last_fill < 1e-6) {
        return(self$tokens)
      }
      new_tokens <- (now - self$last_fill) * self$fill_rate

      self$tokens <- min(self$capacity, self$tokens + new_tokens)
      self$last_fill <- now

      self$tokens
    },

    token_wait_time = function() {
      if (self$tokens >= 1) {
        0
      } else {
        (1 - self$tokens) / self$fill_rate
      }
    },

    # Returns the number of seconds that you need to wait to get it
    # Might cause tokens to drop below 0 temporarily so if you don't end up
    # waiting this long, you need to return the token
    take_token = function() {
      self$refill()
      wait <- self$token_wait_time()
      self$tokens <- self$tokens - 1
      wait
    },

    return_token = function() {
      self$tokens <- min(self$tokens + 1, self$capacity)
    }
  )
)
