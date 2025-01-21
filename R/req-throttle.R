#' Rate limit a request by automatically adding a delay
#'
#' @description
#' Use `req_throttle()` to ensure that repeated calls to [req_perform()] never
#' exceed a specified rate.
#'
#' @inheritParams req_perform
#' @param rate Maximum rate, i.e. maximum number of requests per second.
#'   Usually easiest expressed as a fraction,
#'   `number_of_requests / number_of_seconds`, e.g. 15 requests per minute
#'   is `15 / 60`.
#' @param realm A string that uniquely identifies the throttle pool to use
#'   (throttling limits always apply *per pool*). If not supplied, defaults
#'   to the hostname of the request.
#' @returns A modified HTTP [request].
#' @seealso [req_retry()] for another way of handling rate-limited APIs.
#' @export
#' @examples
#' # Ensure we never send more than 30 requests a minute
#' req <- request(example_url()) |>
#'   req_throttle(rate = 30 / 60)
#'
#' resp <- req_perform(req)
#' throttle_status()
#' resp <- req_perform(req)
#' throttle_status()
req_throttle <- function(req, rate, realm = NULL) {
  check_request(req)
  check_number_decimal(rate)

  delay <- 1 / rate

  throttle_delay <- function(req) {
    realm <- realm %||% url_parse(req$url)$hostname
    last <- the$throttle[[realm]]

    if (is.null(last)) {
      wait <- 0
    } else {
      wait <- max(delay - (unix_time() - last), 0)
    }

    sys_sleep(wait, "for throttling delay")
    throttle_touch(realm)
    wait
  }

  req_policies(req, throttle_delay = throttle_delay)
}

#' Display internal throttle status
#'
#' Sometimes useful for debugging.
#'
#' @return A data frame with two columns: the `realm` and time the
#'   `last_request` was made.
#' @export
#' @keywords internal
throttle_status <- function() {
  realms <- sort(names(the$throttle))

  data.frame(
    realm = realms,
    last_request = .POSIXct(unlist(the$throttle[realms]) %||% double()),
    row.names = NULL,
    check.names = FALSE
  )
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
