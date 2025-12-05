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
#' @inheritParams req_perform
#' @param capacity The size of the bucket, i.e. the maximum number of
#'   tokens that can accumulate.
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
#'
#' \dontshow{httr2:::throttle_reset()}
req_throttle <- function(req, rate, capacity, fill_time_s = 60, realm = NULL) {
  check_request(req)
  check_exclusive(rate, capacity)
  if (missing(capacity)) {
    check_number_decimal(rate, min = 0)
    capacity <- rate * fill_time_s
  } else {
    check_number_whole(capacity, min = 0)
    rate <- capacity / fill_time_s
  }
  check_number_decimal(fill_time_s, min = 0)
  check_string(realm, allow_null = TRUE)

  realm <- realm %||% url_parse(req$url)$hostname
  if (!throttle_exists(realm, capacity, rate)) {
    the$throttle[[realm]] <- TokenBucket$new(capacity, rate)
  }
  req_policies(req, throttle_realm = realm)
}

#' Display internal throttle status
#'
#' Sometimes useful for debugging.
#'
#' @return A data frame with three columns:
#'   * The `realm`.
#'   * Number of `tokens` remaining in the bucket.
#'   * Time `to_wait` in seconds for next token.
#' @export
#' @keywords internal
throttle_status <- function() {
  # Trigger refill before displaying status
  walk(the$throttle, function(x) x$refill())

  df <- data.frame(
    realm = env_names(the$throttle),
    tokens = floor(map_dbl(the$throttle, function(x) x$tokens)),
    to_wait = map_dbl(the$throttle, function(x) x$token_wait_time()),
    row.names = NULL,
    check.names = FALSE
  )
  df[order(df$realm), , drop = FALSE]
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

  cur_throttle <- the$throttle[[realm]]
  cur_throttle$capacity == capacity && cur_throttle$fill_rate == fill_rate
}

throttle_delay <- function(req) {
  if (!req_policy_exists(req, "throttle_realm")) {
    0
  } else {
    the$throttle[[req$policies$throttle_realm]]$take_token()
  }
}
throttle_deadline <- function(req) {
  unix_time() + throttle_delay(req)
}
throttle_return_token <- function(req) {
  the$throttle[[req$policies$throttle_realm]]$return_token()
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
        self$refill()
        (1 - self$tokens) / self$fill_rate
      }
    },

    # Returns the number of seconds that you need to wait to get it
    # Might cause tokens to drop below 0 temporarily so if you don't end up
    # waiting this long, you need to return the token
    take_token = function() {
      wait <- self$token_wait_time()
      self$tokens <- self$tokens - 1
      wait
    },

    return_token = function() {
      self$tokens <- min(self$tokens + 1, self$capacity)
    }
  )
)
