#' Tools for working with lists of responses
#'
#' * `resps_combine()` combines the data from each response into a single
#'   vector.
#' * `resps_response()` returns all successful responses.
#' * `resps_error()` returns all errors.
#'
#' @export
#' @param resps A list of responses (possibly including errors).
#' @param resp_data A function that takes a response (`resp`) and
#'   returns its data as a vector or data frame.
resps_combine <- function(resps, resp_data) {
  check_installed("vctrs")

  check_function2(resp_data, "resp")
  vctrs::list_unchop(lapply(resps, resp_data))
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
