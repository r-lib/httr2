#' Perform multiple requests in sequence
#'
#' Given a list of requests, this function requests each one turn, returning
#' a list of responses.
#'
#' @inheritParams req_perform_sequential
#' @inheritParams req_perform_iteratively
#' @export
#' @examples
#' req <- request("https://api.restful-api.dev/objects")
#' ids <- sort(sample(100, 50))
#' chunks <- split(ids, (seq_along(ids) - 1) %/% (length(ids) / 10))
#' reqs <- chunks %>% lapply(\(idx) req %>% req_url_query(id = idx, .multi = "comma"))
#' resps <- reqs %>% req_perform_sequential()
#' resps_data(resps, \(resp) resp_body_json(resp))
req_perform_sequential <- function(reqs, paths = NULL, progress = TRUE) {
  if (!is.list(reqs)) {
    stop_input_type(reqs, "a list")
  }
  if (!is.null(paths)) {
    if (length(reqs) != length(paths)) {
      cli::cli_abort("If supplied, {.arg paths} must be the same length as {.arg req}.")
    }
  }

  progress <- create_progress_bar(
    total = length(reqs),
    name = "Iterating",
    config = progress
  )

  resps <- rep_along(reqs, list())

  tryCatch({
    for (i in seq_along(reqs)) {
      check_request(reqs[[i]], arg = glue::glue("req[[{i}]]"))
      resps[[i]] <- req_perform(reqs[[i]], path = paths[[i]])
      progress$update()
    }
  }, interrupt = function(cnd) {
    cli::cli_alert_warning(
      "Terminating iteration; returning {i} response{?s}."
    )
  })
  progress$done()

  resps
}
