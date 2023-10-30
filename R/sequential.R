#' Perform multiple requests in sequence
#'
#' Given a list of requests, this function performs each in turn, returning
#' a list of responses. It's slower than [req_perform_parallel()] but
#' has fewer limitations.
#'
#' @inheritParams req_perform_parallel
#' @inheritParams req_perform_iteratively
#' @param on_error What should happen if one of the requests throws an
#'   HTTP error?
#'
#'   * `stop`, the default: stop iterating and throw an error
#'   * `return`: stop iterating and return all the successful responses so far.
#'   * `continue`: continue iterating, recording errors in the result.
#' @export
#' @return
#' A list, the same length as `reqs`.
#'
#' If `on_error` is `"return"` and it errors on the ith request, the ith
#' element of the result will be an error object, and the remaining elements
#' will be `NULL`.
#'
#' If `on_error` is `"continue"`, it will be a mix of requests and errors.
#' @examples
#' # One use of req_perform_sequential() is if the API allows you to request
#' # data for multiple objects, you want data for more objects than can fit
#' # in one request.
#' req <- request("https://api.restful-api.dev/objects")
#'
#' # Imagine we have 50 ids:
#' ids <- sort(sample(100, 50))
#'
#' # But the API only allows us to request 10 at time. So we first use split
#' # and some modulo arithmetic magic to generate chunks of length 10
#' chunks <- unname(split(ids, (seq_along(ids) - 1) %/% 10))
#'
#' # Then we use lapply to generate one request for each chunk:
#' reqs <- chunks %>% lapply(\(idx) req %>% req_url_query(id = idx, .multi = "comma"))
#'
#' # Then we can perform them all and get the results
#' \dontrun{
#' resps <- reqs %>% req_perform_sequential()
#' resps_data(resps, \(resp) resp_body_json(resp))
#' }
req_perform_sequential <- function(reqs,
                                   paths = NULL,
                                   on_error = c("stop", "return", "continue"),
                                   progress = TRUE) {
  if (!is_bare_list(reqs)) {
    stop_input_type(reqs, "a list")
  }
  if (!is.null(paths)) {
    check_character(paths)
    if (length(reqs) != length(paths)) {
      cli::cli_abort("If supplied, {.arg paths} must be the same length as {.arg req}.")
    }
  }
  on_error <- arg_match(on_error)
  err_catch <- on_error != "stop"
  err_return <- on_error == "return"

  progress <- create_progress_bar(
    total = length(reqs),
    name = "Iterating",
    config = progress
  )

  resps <- rep_along(reqs, list())

  tryCatch({
    for (i in seq_along(reqs)) {
      check_request(reqs[[i]], arg = glue::glue("req[[{i}]]"))

      if (err_catch) {
        resps[[i]] <- tryCatch(
          req_perform(reqs[[i]], path = paths[[i]]),
          httr2_error = function(err) err
        )
      } else {
        resps[[i]] <- req_perform(reqs[[i]], path = paths[[i]])
      }
      if (err_return && is_error(resps[[i]])) {
        break
      }
      progress$update()
    }
  }, interrupt = function(cnd) {
    resps <- resps[seq_len(i)]
    cli::cli_alert_warning("Terminating iteration; returning {i} response{?s}.")
  })
  progress$done()

  resps
}
