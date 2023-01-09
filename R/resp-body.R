#' Extract body from response
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
#' @returns
#' * `resp_body_raw()` returns a raw vector.
#' * `resp_body_string()` returns a string.
#' * `resp_body_json()` returns NULL, an atomic vector, or list.
#' * `resp_body_html()` and `resp_body_xml()` return an `xml2::xml_document`
#' @export
#' @examples
#' resp <- request("https://httr2.r-lib.org") %>% req_perform()
#' resp
#'
#' resp %>% resp_body_raw()
#' resp %>% resp_body_string()
#'
#' if (requireNamespace("xml2", quietly = TRUE)) {
#'   resp %>% resp_body_html()
#' }
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
#' @param ... Other arguments passed on to [jsonlite::fromJSON()] and
#'   [xml2::read_xml()] respectively.
#' @rdname resp_body_raw
#' @export
resp_body_json <- function(resp, check_type = TRUE, simplifyVector = FALSE, ...) {
  check_response(resp)
  check_installed("jsonlite")
  check_resp_content_type(resp,
    types = "application/json",
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
  check_resp_content_type(resp,
    types = c("text/html", "application/xhtml+xml"),
    check_type = check_type)

  xml2::read_html(resp$body, ...)
}

#' @rdname resp_body_raw
#' @export
resp_body_xml <- function(resp, check_type = TRUE, ...) {
  check_response(resp)
  check_installed("xml2")
  check_resp_content_type(resp,
    types = c("application/xml", "text/xml"),
    check_type = check_type
  )

  xml2::read_xml(resp$body, ...)
}

# Helpers -----------------------------------------------------------------

check_resp_content_type <- function(resp,
                                    types,
                                    check_type = TRUE,
                                    call = caller_env()) {
  if (!check_type) {
    return()
  }

  content_type <- resp_content_type(resp)
  check_content_type(
    content_type,
    types,
    inform_check_type = TRUE,
    call = call
  )
}

check_content_type <- function(content_type,
                               valid_types,
                               inform_check_type,
                               call = caller_env()) {
  suffix <- NULL
  if (content_type %in% valid_types) {
    return()
  }

  # https://datatracker.ietf.org/doc/html/rfc6838#section-4.2.8
  valid_types_list <- strsplit(valid_types, "/", fixed = TRUE)
  for (valid_type in valid_types_list) {
    type <- valid_type[[1]]
    subtype <- valid_type[[2]]
    if (is_content_type(content_type, type, subtype)) {
      return()
    }
  }

  if (length(valid_types) > 1) {
    type <- paste0("one of ", paste0("'", valid_types, "'", collapse = ", "))
  } else {
    type <- paste0("'", valid_types, "'")
  }

  abort(c(
    glue("Unexpected content type '{content_type}'"),
    glue("Expecting {type}"),
    if (!is.null(suffix)) glue("Or suffix '{suffix}'"),
    i = if (inform_check_type) "Override check with `check_type = FALSE`"
  ), call = call)
}

is_content_type <- function(content_type, type, subtype) {
  if (grepl("+", subtype, fixed = TRUE)) {
    matches <- identical(paste0(type, "/", subtype), content_type)
    return(matches)
  }

  if (!startsWith(content_type, type)) {
    return(FALSE)
  }

  if (!endsWith(content_type, subtype)) {
    return(FALSE)
  }

  TRUE
}

