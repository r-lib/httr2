#' Throttle a request by automatically adding a delay
#'
#' Throttling a request ensures that it never makes more than the specified
#' number of requests per second.
#'
#' @inheritParams req_fetch
#' @param requests_per_second Maximum number of requests per second - usually
#'   easier to specify as a fraction, `number_of_requests / number_of_seconds`.
#'   For example, if you want to make 15 requests per minute, write `15 / 60`.
#' @export
req_throttle <- function(req, requests_per_second) {
  check_request(req)
  check_number(requests_per_second, "`requests_per_second`")

  last <- NULL
  delay <- 1 / requests_per_second

  throttle_delay <- function() {
    if (is.null(last)) {
      wait <- 0
    } else {
      wait <- delay - (unix_time() - last)
    }
    last <<- unix_time()
    wait
  }

  req_policies(req, throttle_delay = throttle_delay)
}

throttle_delay <- function(req) {
  req_policy_call(req, "throttle_delay", list(), default = 0)
}


