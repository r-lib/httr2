#' Tools for working with lists of responses
#'
#' @description
#' These function provide a basic toolkit for operating with lists of
#' responses and possibly errors, as returned by [req_perform_parallel()],
#' [req_perform_sequential()] and [req_perform_iterative()].
#'
#' * `resps_successes()` returns a list successful responses.
#' * `resps_failures()` returns a list failed responses (i.e. errors).
#' * `resps_requests()` returns the list of requests that corresponds to
#'   each request.
#' * `resps_data()` returns all the data in a single vector or data frame.
#'   It requires the vctrs package to be installed.
#'
#' @export
#' @param resps A list of responses (possibly including errors).
#' @param resp_data A function that takes a response (`resp`) and
#'   returns the data found inside that response as a vector or data frame.
#'
#'   NB: If you're using [resp_body_raw()], you're likely to want to wrap its
#'   output in `list()` to avoid combining all the bodies into a single raw
#'   vector, e.g. `resps |> resps_data(\(resp) list(resp_body_raw(resp)))`.
#'
#' @examples
#' reqs <- list(
#'   request(example_url()) |> req_url_path("/ip"),
#'   request(example_url()) |> req_url_path("/user-agent"),
#'   request(example_url()) |> req_template("/status/:status", status = 404),
#'   request("INVALID")
#' )
#' resps <- req_perform_parallel(reqs, on_error = "continue")
#'
#' # find successful responses
#' resps |> resps_successes()
#'
#' # collect all their data
#' resps |>
#'   resps_successes() |>
#'   resps_data(\(resp) resp_body_json(resp))
#'
#' # find requests corresponding to failure responses
#' resps |>
#'   resps_failures() |>
#'   resps_requests()
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
