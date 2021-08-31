#' Extract the body from the response
#'
#' @description
#' * `resp_body_raw()` returns the raw bytes.
#' * `resp_body_string()` returns a UTF-8 string.
#' * `resp_body_json()` returns parsed JSON.
#' * `resp_body_html()` returns parsed HTML.
#' * `resp_body_xml()` returns parsed XML.
#'
#' `resp_body_json()` and `resp_body_xml()` check that the content-type header
#' is correct; if the server returns an incorrect type you can suppress the
#' check with `check_type = FALSE`.
#'
#' @param resp A response object.
#' @export
resp_body_raw <- function(resp) {
  check_response(resp)

  if (is_path(resp$body)) {
    readBin(resp$body, "raw", file.size(resp$body))
  } else if (length(resp$body) == 0) {
    abort("Can not retrieve empty body")
  } else {
    resp$body
  }
}

#' @param encoding Character encoding of the body text. If not specified,
#'   will use the encoding specified by the content-type, falling back to
#'   UTF-8 with a warning if it cannot be found. The resulting string is
#'   always re-encoded to UTF-8.
#' @rdname resp_body_raw
#' @export
resp_body_string <- function(resp, encoding = NULL) {
  check_response(resp)
  encoding <- encoding %||% resp_encoding(resp)

  body <- resp_body_raw(resp)
  iconv(readBin(body, character()), from = encoding, to = "UTF-8")
}

#' @param check_type Check that response has expected content type? Set to
#'   `FALSE` to suppress the automated check
#' @param simplifyVector Should JSON arrays containing only primitives (i.e.
#'   booleans, numbers, and strings) be caused to atomic vectors?
#' @param ... Other argumented passed on to [jsonlite::fromJSON()] and
#'   [xml2::read_xml()] respectively.
#' @rdname resp_body_raw
#' @export
resp_body_json <- function(resp, check_type = TRUE, simplifyVector = FALSE, ...) {
  check_response(resp)
  check_installed("jsonlite")
  check_content_type(resp,
    types = "application/json",
    suffix = "+json",
    check_type = check_type
  )

  text <- resp_body_string(resp, "UTF-8")
  jsonlite::fromJSON(text, simplifyVector = simplifyVector, ...)
}

#' @rdname resp_body_raw
#' @export
resp_body_html <- function(resp, check_type = TRUE, ...) {
  check_response(resp)
  check_installed("xml2")
  check_content_type(resp,
    types = c("text/html", "application/xhtml+xml"),
    check_type = check_type)

  xml2::read_html(resp$body, ...)
}

#' @rdname resp_body_raw
#' @export
resp_body_xml <- function(resp, check_type = TRUE, ...) {
  check_response(resp)
  check_installed("xml2")
  check_content_type(resp,
    types = c("application/xml", "text/xml"),
    suffix = "+xml",
    check_type = check_type
  )

  xml2::read_xml(resp$body, ...)
}

# Helpers -----------------------------------------------------------------

check_content_type <- function(
    resp,
    types,
    suffix = NULL,
    check_type = TRUE) {

  if (!check_type) {
    return()
  }

  content_type <- resp_content_type(resp)
  if (content_type %in% types) {
    return()
  }

  # https://datatracker.ietf.org/doc/html/rfc6838#section-4.2.8
  if (!is.null(suffix) && endsWith(content_type, suffix)) {
    return()
  }

  if (length(types) > 1) {
    type <- paste0("one of ", paste0("'", types, "'", collapse = ", "))
  } else {
    type <- paste0("'", types, "'")
  }

  abort(c(
    glue("Unexpected content type '{content_type}'"),
    glue("Expecting {type}"),
    if (!is.null(suffix)) glue("Or suffix '{suffix}'"),
    i = "Override check with `check_type = FALSE`"
  ))
}

