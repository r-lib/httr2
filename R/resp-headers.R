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
  type <- resp_header(resp, "content-type")
  tryCatch(
    error = function(err) NA_character_,
    httr::parse_media(type)$complete
  )
}

resp_encoding <- function(resp) {
  type <- resp_header(resp, "content-type")
  charset <- tryCatch(
    error = function(err) NULL,
    httr::parse_media(type)$params$charset
  )

  if (is.null(charset)) {
    warn("No encoding found; guessing UTF-8")
    "UTF-8"
  } else {
    charset
  }
}

