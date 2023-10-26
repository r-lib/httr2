#' Tools for working with lists of responses
#'
#' @description
#' These function provide a basic toolkit for operating with lists of
#' responses as returned [req_perform_parallel()] and
#' [req_perform_iteratively()].
#'
#' * `resp_ok()` returns a logical vector which is `TRUE` if the response was
#'   successful, and `FALSE` otherwise.
#' * `resps_combine()` combines the data from successful responses into a
#'   single vector. It requires the vctrs package to be installed.
#' * `resps_requests()` returns the requests corresponding to each response.
#'
#' @export
#' @param resps A list of responses (possibly including errors).
#' @param resp_data A function that takes a response (`resp`) and
#'   returns the data foind inside that response as a vector or data frame.
#' @examples
#' reqs <- list(
#'   request(example_url()) |> req_url_path("/ip"),
#'   request(example_url()) |> req_url_path("/user-agent"),
#'   request(example_url()) |> req_template("/status/:status", status = 404),
#'   request("INVALID")
#' )
#' resps <- req_perform_parallel(reqs)
#'
#' # find successful responses
#' resps |> resps_successes()
#'
#' # collect all their data
#' resps |> resps_successes() |> resps_data(\(resp) resp_body_json(resp))
#'
#' # find requests corresponding to failure responses
#' resps |> resps_failures() |> resps_requests()
resps_successes <- function(resps) {
  resps[resps_ok(resps)]
}

#' @export
#' @rdname resps_successes
resps_failures <- function(resps) {
  resps[!resps_ok(resps)]
}

resps_ok <- function(resps) {
  vapply(resps, is_response, logical(1))
}

#' @export
#' @rdname resps_successes
resps_requests <- function(resps) {
  lapply(resps, function(x) x$request)
}

#' @export
#' @rdname resps_successes
resps_data <- function(resps, resp_data) {
  check_installed("vctrs")
  check_function2(resp_data, "resp")

  vctrs::list_unchop(lapply(resps, resp_data))
}
