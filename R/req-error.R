#' Control handling of HTTP errors
#'
#' `req_perform()` will automatically convert HTTP errors (i.e. any 4xx or 5xx
#' status code) into R errors. Use `req_error()` to either override the
#' defaults, or extract additional information from the response that would
#' be useful to expose to the user.
#'
#' # Error handling
#'
#' `req_perform()` is designed to succeed if and only if you get a valid HTTP
#' response. There are two ways a request can fail:
#'
#' * The HTTP request might fail, for example if the connection is dropped
#'   or the server doesn't exist. This type of error will have class
#'   `httr2_failure`.
#'
#' * The HTTP request might succeed, but return an HTTP status code that
#'   represents a error, e.g. a `404 Not Found` if the specified resource is
#'   not found. This type of error will have (e.g.) class
#'   `c("httr2_http_404", "httr2_http")`.
#'
#' These error classes are designed to be used in conjunction with R's
#' condition handling tools (<https://adv-r.hadley.nz/conditions.html>).
#' For example, if you want to return a default value when the server returns
#' a 404, use `tryCatch()`:
#'
#' ```
#' tryCatch(
#'   req |> req_perform() |> resp_body_json(),
#'   httr2_http_404 = function(cnd) NULL
#' )
#' ```
#'
#' Or if you want to re-throw the error with some additional context, use
#' `withCallingHandlers()`, e.g.:
#'
#' ```R
#' withCallingHandlers(
#'   req |> req_perform() |> resp_body_json(),
#'   httr2_http_404 = function(cnd) {
#'     rlang::abort("Couldn't find user", parent = cnd)
#'   }
#' )
#' ```
#'
#' Learn more about error chaining at [rlang::topic-error-chaining].
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
#' req <- request(example_url()) |>
#'   req_url_path("/status/404")
#' try(req |> req_perform())
#' # You can still retrieve it with last_response()
#' last_response()
#'
#' # But you might want to suppress this behaviour:
#' resp <- req |>
#'   req_error(is_error = \(resp) FALSE) |>
#'   req_perform()
#' resp
#'
#' # Or perhaps you're working with a server that routinely uses the
#' # wrong HTTP error codes only 500s are really errors
#' request("http://example.com") |>
#'   req_error(is_error = \(resp) resp_status(resp) == 500)
#'
#' # Most typically you'll use req_error() to add additional information
#' # extracted from the response body (or sometimes header):
#' error_body <- function(resp) {
#'   resp_body_json(resp)$error
#' }
#' request("http://example.com") |>
#'   req_error(body = error_body)
#' # Learn more in https://httr2.r-lib.org/articles/wrapping-apis.html
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

error_body <- function(req, resp, call = caller_env()) {
  try_fetch(
    req_policy_call(req, "error_body", list(resp), default = NULL),
    error = function(cnd) {
      cli::cli_abort(
        "Failed to parse error body with method defined in {.fn req_error}.",
        parent = cnd,
        call = call
      )
    }
  )
}
