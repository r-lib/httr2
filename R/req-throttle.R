#' Throttle a request by automatically adding a delay
#'
#' Use `req_throttle()` to ensure that repeated calls to [req_perform()] never
#' exceed a specified rate.
#'
#' @inheritParams req_perform
#' @param rate Maximum rate, i.e. maximum number of requests per second.
#'   Usually easiest expressed as a fraction,
#'   `number_of_requests / number_of_seconds`, e.g. 15 requests per minute
#'   is `15 / 60`.
#' @param realm An unique identifier that for throttle pool. If not supplied,
#'   defaults to the hostname of the request.
#' @returns A modified HTTP [request].
#' @seealso [req_retry()] for another way of handling rate-limited APIs.
#' @export
#' @examples
#' # Ensure server will never recieve more than 10 requests a minute
#' request("https://example.com") %>%
#'   req_throttle(rate = 10 / 60)
req_throttle <- function(req, rate, realm = NULL) {
  check_request(req)
  check_number(rate, "`rate`")

  delay <- 1 / rate

  throttle_delay <- function(req) {
    realm <- realm %||% url_parse(req$url)$hostname
    last <- the$throttle[[realm]]

    if (is.null(last)) {
      wait <- 0
    } else {
      wait <- delay - (unix_time() - last)
    }

    sys_sleep(wait)
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
