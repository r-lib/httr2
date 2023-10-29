#' Temporarily mock requests
#'
#' Mocking allows you to selectively and temporarily replace the response
#' you would typically receive from a request with your own code. It's
#' primarily used for testing.
#'
#' @param mock A function, a list, or `NULL`.
#'
#'   * `NULL` disables mocking and returns httr2 to regular operation.
#'
#'   * A list of responses will be returned in sequence. After all responses
#'     have been used up, will return 503 server errors.
#'
#'   * For maximum flexibility, you can supply a function that that takes a
#'     single argument, `req`, and returns either `NULL` (if it doesn't want to
#'     handle the request) or a [response] (if it does).
#'
#' @param code Code to execute in the temporary environment.
#' @param env Environment to use for scoping changes.
#' @returns `with_mock()` returns the result of evaluating `code`.
#' @export
#' @examples
#' # This function should perform a response against google.com:
#' google <- function() {
#'   request("http://google.com") |>
#'     req_perform()
#' }
#'
#' # But I can use a mock to instead return my own made up response:
#' my_mock <- function(req) {
#'   response(status_code = 403)
#' }
#' try(with_mock(my_mock, google()))
with_mocked_responses <- function(mock, code) {
  mock <- as_mock_function(mock)
  withr::with_options(list(httr2_mock = mock), code)
}

#' @export
#' @rdname with_mocked_responses
#' @usage NULL
with_mock <- function(mock, code) {
  lifecycle::deprecate_warn("1.0.0", "with_mock()", "with_mocked_responses()")
  with_mocked_responses(mock, code)
}

#' @export
#' @rdname with_mocked_responses
local_mocked_responses <- function(mock, env = caller_env()) {
  mock <- as_mock_function(mock)
  withr::local_options(httr2_mock = mock, .local_envir = env)
}

#' @export
#' @rdname with_mocked_responses
#' @usage NULL
local_mock <- function(mock, env = caller_env()) {
  lifecycle::deprecate_warn("1.0.0", "local_mock()", "local_mocked_responses()")
  local_mocked_responses(mock, env)
}

as_mock_function <- function(mock, error_call = caller_env()) {
  if (is.null(mock)) {
    mock
  } else if (is.function(mock)) {
    check_function2(mock, args = "req", call = error_call)
    mock
  } else if (is_formula(mock)) {
    mock <- as_function(mock, call = error_call)
  } else if (is.list(mock)) {
    mocked_response_sequence(!!!mock)
  } else {
    cli::cli_abort(
      "{.arg mock} must be a function or list, not {.obj_type_friendly {mock}}.",
      call = error_call
    )
  }
}

mocked_response_sequence <- function(...) {
  responses <- list2(...)

  n <- length(responses)
  i <- 0
  function(req) {
    if (i >= n) {
      response(503)
    } else {
      i <<- i + 1
      responses[[i]]
    }
  }
}
