#' Control handling of HTTP errors
#'
#' `req_fetch()` will automatically convert HTTP errors (i.e. any 4xx or 5xx
#' status code) into R errors, but you can override with `is_error`. If the
#' API provides useful additional information in the response, you can use
#' `info` to extract into a character vector that will be automatically
#' appended to the generated error.
#'
#' @seealso [req_retry()] to control when errors are automatically retried.
#' @inheritParams req_fetch
#' @param is_error A predicate function that takes a single argument (the
#'   response) and returns `TRUE` or `FALSE` indicating whether or not an
#'   R error should signalled.
#' @param info A callback function that takes a single argument (the response)
#'   and returns a character vector of additional information about the error.
#'   This vector is passed along to the `message` argument of [rlang::abort()]
#'   so you can use any formatting that it supports.
#' @export
req_error <- function(req,
                      is_error = NULL,
                      info = NULL) {
  check_request(req)

  req_policies(
    req,
    error_is_error = as_callback(is_error, 1, "is_error"),
    error_info = as_callback(info, 1, "info")
  )
}

error_is_error <- function(req, resp) {
  req_policy_call(req, "error_is_error", list(resp), default = resp_is_error)
}

error_info <- function(req, resp) {
  req_policy_call(req, "error_info", list(resp), default = NULL)
}
