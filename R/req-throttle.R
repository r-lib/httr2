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
  last <- NULL
  delay <- 1 / requests_per_second

  req$policies$throttle <- function(resp) {
    if (is.null(last)) {
      wait <- 0
    } else {
      wait <- delay - (Sys.time() - last)
    }
    last <<- Sys.time()
    wait
  }
  req
}

throttle_delay <- function(req, resp) {
  if (req_has_policy(req, "throttle")) {
    req$hook$throttle(resp)
  } else {
    0
  }
}
