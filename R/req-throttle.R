#' Throttle a request by automatically adding a delay
#'
#' Throttling a request ensures that it never makes more than the specified
#' number of requests per second.
#'
#' @inheritParams req_fetch
#' @param rate Maximum rate, i.e. maximum number of requests per second.
#'   Usually easiest expressed as a fraction,
#'   `number_of_requests / number_of_seconds`, e.g. 15 requests per minute
#'   is `15 / 60`.
#' @param realm An unique identifier that for throttle pool. If not supplied,
#'   defaults to the hostname of the request.
#' @export
req_throttle <- function(req, rate, realm = NULL) {
  check_request(req)
  check_number(rate, "`rate`")

  delay <- 1 / rate

  throttle_delay <- function(req) {
    realm <- realm %||% httr::parse_url(req$url)$hostname
    last <- the$throttle[[realm]]

    if (is.null(last)) {
      wait <- 0
    } else {
      wait <- delay - (unix_time() - last)
    }

    throttle_touch(realm)
    wait
  }

  req_policies(req, throttle_delay = throttle_delay)
}

throttle_reset <- function() {
  env_bind(the, throttle = list())
  invisible()
}
throttle_touch <- function(realm) {
  env_bind(the, throttle = modify_list(the$throttle, !!realm := unix_time()))
}

throttle_delay <- function(req) {
  req_policy_call(req, "throttle_delay", list(req), default = 0)
}
