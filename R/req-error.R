#' Control handling of HTTP errors
#'
#' `req_perform()` will automatically convert HTTP errors (i.e. any 4xx or 5xx
#' status code) into R errors. Use `req_perform()` to either override the
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
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' # Performing this request usually generates an error because httr2
#' # converts HTTP errors into R errors:
#' req <- request("http://httpbin.org/404")
#' try(req %>% req_perform())
#' # You can still retrieve it with last_response()
#' last_response()
#'
#' # But you might want to suppress this behaviour:
#' resp <- req %>%
#'   req_error(is_error = function(resp) FALSE) %>%
#'   req_perform()
#' resp
#'
#' # Or perhaps you're working with a server that routinely uses the
#' # wrong HTTP error codes only 500s are really errors
#' request("http://example.com") %>%
#'   req_error(is_error = function(resp) resp_status(resp) == 500)
#'
#' # Most typically you'll use req_error() to add additional information
#' # extracted from the response body (or sometimes header):
#' error_body <- function(resp) {
#'   resp_body_json(resp)$error
#' }
#' request("http://example.com") %>%
#'   req_error(body = extra_info)
#' # Learn more in vignette("wrapping-apis")
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
