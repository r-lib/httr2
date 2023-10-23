#' Tools for working with lists of responses
#'
#' * `resps_combine()` combines the data from each responses into a single
#'   object.
#' * `resps_response()` returns all successful responses.
#' * `resps_error()` returns all errors.
#'
#' @export
#' @param resps A list of responses (possibly including errors).
#' @param resp_data A function that takes a response (`resp`) and
#'   returns its data as a vector or data frame.
#' @param resp_data A function with one argument `resp` that parses the
#'   response and returns a list with the field `data` and other fields needed
#'   to create the request for the next page.
#'   `req_perform_iteratively()` combines all `data` fields via [vctrs::vec_c()]
#'   and returns the result.
#'   Other fields that might be needed are:
#'
#'     * `next_url` for `paginate_next_url()`.
#'     * `next_token` for `paginate_next_token()`.
#'
resps_combine <- function(resps, resp_data) {
  check_installed("vctrs")

  check_function2(resp_data, "body")
  vctrs::vec_c(!!!lapply(resps, resp_data))
}
resps_is_resp <- function(resps) {
  vapply(resps, is_response, logical(1))
}

#' @export
#' @rdname resps_combine
resps_responses <- function(resps) {
  resps[resps_is_resp(resps)]
}
#' @export
#' @rdname resps_combine
resps_errors <- function(resps) {
  resps[!resps_is_resp(resps)]
}
