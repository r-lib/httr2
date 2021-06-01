#' Extract headers from a response
#'
#' @description
#' Some of these functions provide generic access to all headers:
#' * `resp_headers()` retrieves a list of all headers.
#' * `resp_header()` retrieves a single header.
#' * `resp_header_exists()` checks if a header is present.
#'
#' Other functions parse specific headers:
#'
#' * `resp_content_type()` returns the just the type and subtype of the
#'    from the `Content-Type` header. If `Content-Type` is not provided
#'    (or is not a valid mime type), this returns `NA`. Used by
#'    [resp_body_json()], [resp_body_html()], and [resp_body_xml()].
#'
#' * `resp_date()` returns the `Date` header as a POSIXct. This header
#'    always exists; if the server does not return it, httr2 adds
#'    automatically.
#'
#' *  `resp_encoding()` returns the likely character encoding of text
#'    types, as parsed from the `charset` parameter of the `Content-Type`
#'    header. If that header is not found, not valid, or no charset parameter
#'    is found, this returns `UTF-8`. Used by [resp_body_string()].
#'
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

#' @export
#' @rdname resp_headers
resp_content_type <- function(resp) {
  resp_parsed_content_type(resp)$complete %||% NA_character_
}

#' @export
#' @rdname resp_headers
resp_date <- function(resp) {
  httr::parse_http_date(resp_header(resp, "Date"), NULL)
}

#' @export
#' @rdname resp_headers
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
