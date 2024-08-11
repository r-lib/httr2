#' Get URL/components from the response
#'
#' * `resp_url()` returns the complete url.
#' * `resp_url_path()` returns the path component.
#' * `resp_url_query()` returns a single query component.
#' * `resp_url_queries()` returns the query component as a named list.
#'
#' @inheritParams resp_header
#' @export
#' @examples
#' resp <- request(example_url()) |>
#'   req_url_path("/get?hello=world") |>
#'   req_perform()
#'
#' resp |> resp_url()
#' resp |> resp_url_path()
#' resp |> resp_url_queries()
#' resp |> resp_url_query("hello")
resp_url <- function(resp) {
  check_response(resp)

  resp$url
}

#' @export
#' @rdname resp_url
resp_url_path <- function(resp) {
  check_response(resp)

  url_parse(resp$url)$path
}

#' @export
#' @rdname resp_url
#' @param name Query parameter name.
#' @param default Default value to use if query parameter doesn't exist.
resp_url_query <- function(resp, name, default = NULL) {
  check_response(resp)

  resp_url_queries(resp)[[name]] %||% default
}

#' @export
#' @rdname resp_url
resp_url_queries <- function(resp) {
  check_response(resp)

  url_parse(resp$url)$query
}
