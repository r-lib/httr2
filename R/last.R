#' Retrieve most recent request/response
#'
#' @description
#' `last_request()` and `last_response()` retrieve the most recent request
#' made by httr2 and the response it received, to facilitate debugging problems
#' _after_ they occur.
#'
#' `last_request_json()` and `last_response_json()` return the JSON bodies of
#' the most recent request and response. They will error if not JSON.
#'
#' @returns `last_request()` and `last_response()` return an HTTP
#'   [request] or [response] respectively. If no request has been made,
#'   `last_request()` will return `NULL`; if no request has been made
#'   or the last request was unsuccessful, `last_response()` will return
#'   `NULL`.
#'
#'   `last_request_json()` and `last_response_json()` always return a string.
#'   They will error if `last_request()` or `last_response()` are `NULL` or
#'   don't have JSON bodies.
#' @export
#' @examples
#' . <- request("http://httr2.r-lib.org") |> req_perform()
#' last_request()
#' last_response()
#'
#' . <- request(example_url("/post")) |>
#'   req_body_json(list(a = 1, b = 2)) |>
#'   req_perform()
#' last_request_json()
#' last_request_json(pretty = FALSE)
#' last_response_json()
#' last_response_json(pretty = FALSE)
last_response <- function() {
  the$last_response
}

#' @export
#' @rdname last_response
last_request <- function() {
  the$last_request
}

#' @export
#' @rdname last_response
last_request_json <- function(pretty = TRUE) {
  req <- last_request()
  if (is.null(req)) {
    cli::cli_abort("No request has been made yet.")
  }
  if (req_body_type(req) != "json") {
    cli::cli_abort("Last request doesn't have a JSON body.")
  }
  httr2_json(req_get_body(req), pretty = pretty)
}

#' @param pretty Should the JSON be pretty-printed?
#' @export
#' @rdname last_response
last_response_json <- function(pretty = TRUE) {
  resp <- last_response()
  if (is.null(resp)) {
    cli::cli_abort("No request has been made successfully yet.")
  }
  if (!identical(resp_content_type(resp), "application/json")) {
    cli::cli_abort("Last response doesn't have a JSON body.")
  }
  httr2_json(resp_body_string(resp), pretty = pretty)
}

httr2_json <- function(x, pretty = TRUE) {
  check_string(x)
  structure(x, pretty = pretty, class = "httr2_json")
}
#' @export
print.httr2_json <- function(x, ...) {
  if (attr(x, "pretty")) {
    cat(pretty_json(x))
  } else {
    cat(x)
  }

  cat("\n")
  invisible(x)
}
