#' Control handling of HTTP errors
#'
#' `req_fetch()` will automatically convert HTTP errors (i.e. any 4xx or 5xx
#' status code) into R errors. Use `req_fetch()` to either override the
#' defaults, or extract additional information from the response that would
#' be useful to expose to the user.
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
#' @returns An HTTP [req]uest.
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
