#' Extract headers from a response
#'
#' @description
#' * `resp_headers()` retrieves a list of all headers.
#' * `resp_header()` retrieves a single header.
#' * `resp_header_exists()` checks if a header is present.
#'
#' @param resp An HTTP response object, as created by [req_perform()].
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
  resp$headers[[header]]
}

#' @export
#' @rdname resp_headers
resp_header_exists <- function(resp, header) {
  check_response(resp)
  tolower(header) %in% tolower(names(resp$headers))
}

#' Extract request date from response
#'
#' All responses contain a request date in the `Date` header; if not provided
#' by the server will be automatically added by httr2.
#'
#' @export
#' @inheritParams resp_headers
resp_date <- function(resp) {
  parse_http_date(resp_header(resp, "Date"))
}

#' Extract response content type and encoding
#'
#' @description
#' `resp_content_type()` returns the just the type and subtype of the
#' from the `Content-Type` header. If `Content-Type` is not provided; it
#' returns `NA`. Used by [resp_body_json()], [resp_body_html()], and
#' [resp_body_xml()].
#'
#' `resp_encoding()` returns the likely character encoding of text
#' types, as parsed from the `charset` parameter of the `Content-Type`
#' header. If that header is not found, not valid, or no charset parameter
#' is found, returns `UTF-8`. Used by [resp_body_string()].
#'
#' @export
#' @inheritParams resp_headers
resp_content_type <- function(resp) {
  if (resp_header_exists(resp, "content-type")) {
    parse_media(resp_header(resp, "content-type"))$type
  } else {
    NA_character_
  }
}

#' @export
#' @rdname resp_content_type
resp_encoding <- function(resp) {
  if (resp_header_exists(resp, "content-type")) {
    parse_media(resp_header(resp, "content-type"))$charset %||% "UTF-8"
  } else {
    "UTF-8"
  }
}

#' Extract wait time from a response
#'
#' Computes how many seconds you should wait before retrying a request by
#' inspecting the `Retry-After` header. It parses both forms (absolute and
#' relative) and returns the number of seconds to wait. If the heading is not
#' found, it will return `NA`.
#'
#' @export
#' @inheritParams resp_headers
resp_retry_after <- function(resp) {
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After
  val <- resp_header(resp, "Retry-After")
  if (is.null(val)) {
    NA
  } else if (grepl(" ", val)) {
    diff <- difftime(parse_http_date(val), resp_date(resp), units = "secs")
    as.numeric(diff)
  } else {
    as.numeric(val)
  }
}

#' Parse link url from a response
#'
#' This parses the `Link` header, extracting the url corresponding to the
#' specified `rel`. Returns `NULL` if not present.
#'
#' @export
#' @inheritParams resp_headers
#' @param rel "rel" value for which to retrieve url
#' @export
#' @examples
#' resp <- request("https://api.github.com/search/code") %>%
#'   req_url_query(q = "addClass user:mozilla") %>%
#'   req_perform()
#' resp_link_url(resp, "next")
resp_link_url <- function(resp, rel) {
  if (!resp_header_exists(resp, "Link")) {
    return()
  }

  links <- parse_link(resp_header(resp, "Link"))
  sel <- map_lgl(links, ~ .$rel == rel)
  if (sum(sel) != 1L) {
    return()
  }

  links[[which(sel)]]$url
}
