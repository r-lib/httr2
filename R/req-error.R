#' Control handling of HTTP errors
#'
#' `req_perform()` will automatically convert HTTP errors (i.e. any 4xx or 5xx
#' status code) into R errors. Use `req_error()` to either override the
#' defaults, or extract additional information from the response that would
#' be useful to expose to the user.
#'
#' @seealso [req_retry()] to control when errors are automatically retried.
#' @inheritParams req_perform
#' @param is_error A predicate function that takes a single argument (the
#'   response) and returns `TRUE` or `FALSE` indicating whether or not an
#'   R error should signalled.
#' @param body A callback function that takes a single argument (the response)
#'   and returns a character vector of additional information to include in the
#'   body of the error. This vector is passed along to the `message` argument
#'   of [rlang::abort()] so you can use any formatting that it supports.
#' @returns An HTTP [request].
#' @export
req_error <- function(req,
                      is_error = NULL,
                      body = NULL) {
  check_request(req)

  req_policies(
    req,
    error_is_error = as_callback(is_error, 1, "is_error"),
    error_body = as_callback(body, 1, "body")
  )
}

error_is_error <- function(req, resp) {
  req_policy_call(req, "error_is_error", list(resp), default = resp_is_error)
}

error_body <- function(req, resp) {
  # TODO: revisit once rlang has better support for this
  tryCatch(
    req_policy_call(req, "error_body", list(resp), default = NULL),
    error = function(cnd) {
      msg <- c(
        "",
        "Additionally, req_error(body = ) failed with error:",
        gsub("\n", "\n  ", conditionMessage(cnd))
      )
      if (utils::packageVersion("rlang") >= "0.4.11.9001") {
        names(msg)[[3]] <- " "
      }
      msg
    }
  )
}
