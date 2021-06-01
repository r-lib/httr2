#' Extract headers from a response
#'
#' * `resp_headers()` retrieves a list of all headers.
#' * `resp_header()` retrieves a single header.
#' * `resp_header_exists()` checks if a header is present
#'
#' @param resp An HTTP response object, as created by [req_fetch()].
#' @export
resp_headers <- function(resp) {
  check_response(resp)
  resp$headers
}

#' @export
#' @param header Header name (case insensitive)
#' @rdname resp_headers
resp_header <- function(resp, header) {
  check_response(resp)
  resp$headers[[tolower(header)]]
}

#' @export
#' @rdname resp_headers
resp_header_exists <- function(resp, header) {
  check_response(resp)
  has_name(resp$headers, tolower(header))
}

resp_content_type <- function(resp) {
  resp_parsed_content_type(resp)$complete %||% NA_character_
}

resp_date <- function(resp) {
  httr::parse_http_date(resp_header(resp, "Date"), NULL)
}

resp_encoding <- function(resp) {
  resp_parsed_content_type(resp)$params$charset %||% "UTF-8"
}

resp_parsed_content_type <- function(resp) {
  type <- resp_header(resp, "content-type")
  tryCatch(
    httr::parse_media(type),
    error = function(err) NULL
  )
}
