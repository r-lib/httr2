#' Extract headers from a response
#'
#' @description
#' * `resp_headers()` retrieves a list of all headers.
#' * `resp_header()` retrieves a single header.
#' * `resp_header_exists()` checks if a header is present.
#'
#' @param resp An HTTP response object, as created by [req_perform()].
#' @param filter A regular expression used to filter the header names.
#'   `NULL`, the default, returns all headers.
#' @return
#' * `resp_headers()` returns a list.
#' * `resp_header()` returns a string if the header exists and `NULL` otherwise.
#' * `resp_header_exists()` returns `TRUE` or `FALSE`.
#' @export
#' @examples
#' resp <- request("https://httr2.r-lib.org") %>% req_perform()
#' resp %>% resp_headers()
#' resp %>% resp_headers("x-")
#'
#' resp %>% resp_header_exists("server")
#' resp %>% resp_header("server")
#' # Headers are case insensitive
#' resp %>% resp_header("SERVER")
#'
#' # Returns NULL if header doesn't exist
#' resp %>% resp_header("this-header-doesnt-exist")
resp_headers <- function(resp, filter = NULL) {
  check_response(resp)

  if (is.null(filter)) {
    resp$headers
  } else {
    resp$headers[grepl(filter, names(resp$headers), perl = TRUE, ignore.case = TRUE)]
  }
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
#' @returns A `POSIXct` date-time.
#' @examples
#' resp <- response(headers = "Date: Wed, 01 Jan 2020 09:23:15 UTC")
#' resp %>% resp_date()
#'
#' # If server doesn't add header (unusual), you get the time the request
#' # was created:
#' resp <- response()
#' resp %>% resp_date()
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
#' @returns A string. If no content type is specified `resp_content_type()`
#'   will return a character `NA`; if no encoding is specified,
#'   `resp_encoding()` will return `"UTF-8"`.
#' @inheritParams resp_headers
#' @examples
#' resp <- response(header = "Content-type: text/html; charset=utf-8")
#' resp %>% resp_content_type()
#' resp %>% resp_encoding()
#'
#' # No Content-Type header
#' resp <- response()
#' resp %>% resp_content_type()
#' resp %>% resp_encoding()
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
#' @returns Scalar double giving the number of seconds to wait before retrying
#'   a request.
#' @inheritParams resp_headers
#' @examples
#' resp <- response(headers = "Retry-After: 30")
#' resp %>% resp_retry_after()
#'
#' resp <- response(headers = "Retry-After: Mon, 20 Sep 2025 21:44:05 UTC")
#' resp %>% resp_retry_after()
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

#' Parse link URL from a response
#'
#' Parses URLs out of the the `Link` header as defined by
#' [rfc8288](https://datatracker.ietf.org/doc/html/rfc8288).
#'
#' @export
#' @inheritParams resp_headers
#' @returns Either a string providing a URL, if the specified `rel` exists, or
#'   `NULL` if not.
#' @param rel The "link relation type" value for which to retrieve a URL.
#' @export
#' @examples
#' # Simulate response from GitHub code search
#' resp <- response(headers = paste0("Link: ",
#'   '<https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2>; rel="next",',
#'   '<https://api.github.com/search/code?q=addClass+user%3Amozilla&page=34>; rel="last"'
#' ))
#'
#' resp_link_url(resp, "next")
#' resp_link_url(resp, "last")
#' resp_link_url(resp, "prev")
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
