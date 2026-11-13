#' Extract body from response
#'
#' @description
#' * `resp_body_raw()` returns the raw bytes.
#' * `resp_body_string()` returns a UTF-8 string.
#' * `resp_body_json()` returns parsed JSON.
#' * `resp_body_html()` returns parsed HTML.
#' * `resp_body_xml()` returns parsed XML.
#' * `resp_body_multipart()` returns a list of per-part responses.
#' * `resp_has_body()` returns `TRUE` if the response has a body.
#'
#' `resp_body_json()`, `resp_body_xml()` and `resp_body_multipart()` check
#' that the content-type header is correct; if the server returns an incorrect
#' type you can suppress the check with `check_type = FALSE`.
#'
#' `resp_body_json()` and `resp_body_xml()` also cache the parsed
#' object so the second and subsequent calls are low-cost.
#'
#' `resp_body_multipart()` splits a `multipart/*` body (e.g.
#' `multipart/byteranges` or `multipart/mixed`) into its parts. Each part is
#' returned as a response with its own headers and body, but the method, URL,
#' and status code are copied from the original response. Parts without a
#' `Content-Type` header are given the default specified by RFC 2046:
#' `message/rfc822` for `multipart/digest`, and `text/plain; charset=US-ASCII`
#' otherwise.
#'
#' @inheritParams resp_headers
#' @returns
#' * `resp_body_raw()` returns a raw vector.
#' * `resp_body_string()` returns a string.
#' * `resp_body_json()` returns NULL, an atomic vector, or list.
#' * `resp_body_html()` and `resp_body_xml()` return an `xml2::xml_document`
#' * `resp_body_multipart()` returns a list of responses, one per part.
#' @export
#' @examples
#' resp <- request("https://httr2.r-lib.org") |> req_perform()
#' resp
#'
#' resp |> resp_has_body()
#' resp |> resp_body_raw()
#' resp |> resp_body_string()
#'
#' if (requireNamespace("xml2", quietly = TRUE)) {
#'   resp |> resp_body_html()
#' }
resp_body_raw <- function(resp) {
  check_response(resp)

  if (!resp_has_body(resp)) {
    cli::cli_abort("Can't retrieve empty body.")
  }

  switch(
    resp_body_type(resp),
    disk = readBin(resp$body, "raw", file.size(resp$body)),
    memory = resp$body,
    stream = resp$body$read_all()
  )
}

#' @rdname resp_body_raw
#' @export
resp_has_body <- function(resp) {
  check_response(resp)

  switch(
    resp_body_type(resp),
    disk = file.size(resp$body) > 0,
    memory = length(resp$body) > 0,
    stream = resp$body$is_open()
  )
}

resp_body_type <- function(resp) {
  if (is_path(resp$body)) {
    "disk"
  } else if (inherits(resp$body, "StreamingBody")) {
    "stream"
  } else {
    "memory"
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
#'   `FALSE` to suppress the automated check.
#' @param simplifyVector Should JSON arrays containing only primitives (i.e.
#'   booleans, numbers, and strings) be caused to atomic vectors?
#' @param ... Other arguments passed on to [jsonlite::fromJSON()] and
#'   [xml2::read_xml()] respectively.
#' @rdname resp_body_raw
#' @export
resp_body_json <- function(
  resp,
  check_type = TRUE,
  simplifyVector = FALSE,
  ...
) {
  check_response(resp)
  check_installed("jsonlite")

  key <- body_cache_key("json", simplifyVector = simplifyVector, ...)
  if (env_has(resp$cache, key)) {
    return(resp$cache[[key]])
  }

  resp_check_content_type(
    resp,
    valid_types = "application/json",
    valid_suffix = "json",
    check_type = check_type
  )

  text <- resp_body_string(resp, "UTF-8")
  resp$cache[[key]] <- jsonlite::fromJSON(
    text,
    simplifyVector = simplifyVector,
    ...
  )
  resp$cache[[key]]
}

#' @rdname resp_body_raw
#' @export
resp_body_html <- function(resp, check_type = TRUE, ...) {
  check_response(resp)
  check_installed("xml2")
  resp_check_content_type(
    resp,
    valid_types = c("text/html", "application/xhtml+xml"),
    check_type = check_type
  )

  body <- resp_body_raw(resp)
  xml2::read_html(body, ...)
}

#' @rdname resp_body_raw
#' @export
resp_body_xml <- function(resp, check_type = TRUE, ...) {
  check_response(resp)
  check_installed("xml2")

  key <- body_cache_key("xml", ...)
  if (env_has(resp$cache, key)) {
    return(resp$cache[[key]])
  }

  resp_check_content_type(
    resp,
    valid_types = c("application/xml", "text/xml"),
    valid_suffix = "xml",
    check_type = check_type
  )

  body <- resp_body_raw(resp)
  resp$cache[[key]] <- xml2::read_xml(body, ...)
  resp$cache[[key]]
}

body_cache_key <- function(prefix, ...) {
  key <- hash(list(...))
  paste0(prefix, "-", substr(key, 1, 10))
}

#' @rdname resp_body_raw
#' @export
resp_body_multipart <- function(resp, check_type = TRUE) {
  resp_check_content_type(resp, "multipart/*", check_type = check_type)

  call <- current_env()
  media <- multipart_media(resp_header(resp, "Content-Type", default = ""))
  boundary <- multipart_boundary(media, error_call = call)
  parts <- multipart_split(resp_body_raw(resp), boundary, error_call = call)

  # https://datatracker.ietf.org/doc/html/rfc2046#section-5.1.5
  if (media$type == "multipart/digest") {
    default_type <- "message/rfc822"
  } else {
    default_type <- "text/plain; charset=US-ASCII"
  }

  lapply(parts, function(part) {
    part <- multipart_parse_part(part, error_call = call)
    part$headers$`Content-Type` <- part$headers$`Content-Type` %||% default_type
    # Use the original response's values to fill in the per-part response.
    new_response(
      resp$method,
      resp$url,
      resp$status_code,
      headers = part$headers,
      body = part$body
    )
  })
}

# Parses a content type, normalising the type and parameter names to lower
# case since both are case-insensitive.
multipart_media <- function(content_type) {
  media <- parse_media(content_type)
  names(media) <- tolower(names(media))
  media$type <- tolower(media$type)
  media
}

# https://datatracker.ietf.org/doc/html/rfc2046#section-5.1.1
multipart_boundary <- function(media, error_call = caller_env()) {
  boundary <- media$boundary %||% ""

  bchars <- "0-9a-zA-Z'()+_,./:=?-"
  regex <- paste0("^[ ", bchars, "]{0,69}[", bchars, "]$")
  if (!grepl(regex, boundary)) {
    cli::cli_abort(
      "Missing or invalid multipart boundary {.str {boundary}}.",
      call = error_call
    )
  }
  boundary
}

# Returns a list of raw vectors, one for each body part. Each part starts with
# the CRLF that terminates its delimiter line, so a part without headers
# starts with a blank line. Works on the raw bytes since binary parts may
# contain embedded nuls.
multipart_split <- function(body, boundary, error_call = caller_env()) {
  # The CRLF preceding a delimiter is part of the delimiter, but the first
  # delimiter may also occur at the very start of the body. Prepending a CRLF
  # lets us handle both cases identically.
  body <- c(charToRaw("\r\n"), body)

  # A delimiter is followed by "--" (closing delimiter) or optional transport
  # padding and CRLF; anything else is a boundary-like string in the body.
  # grepRaw() doesn't support perl = TRUE, so we must escape by hand.
  escaped <- gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", boundary)
  pattern <- paste0("\r\n--", escaped, "(--|[ \t]*\r\n)")
  start <- grepRaw(pattern, body, all = TRUE)
  match <- grepRaw(pattern, body, all = TRUE, value = TRUE)
  # Only a closing delimiter ends in "-"
  is_close <- body[start + lengths(match) - 1L] == charToRaw("-")

  close <- which(is_close)[1]
  if (is.na(close) || close == 1) {
    cli::cli_abort(
      "Failed to find any parts in multipart response body.",
      call = error_call
    )
  }

  # Keep the trailing CRLF of each delimiter line
  part_start <- (start + lengths(match) - 2L)[seq_len(close - 1)]
  part_end <- start[seq2(2, close)] - 1L
  map2(part_start, part_end, \(start, end) body[seq2(start, end)])
}

# Splits a body part (starting with CRLF) into headers and body.
multipart_parse_part <- function(part, error_call = caller_env()) {
  n <- length(part)
  if (n == 2) {
    return(list(headers = as_headers(list()), body = raw()))
  }

  # Headers must be terminated by an empty line
  end <- grepRaw("\r\n\r\n", part, fixed = TRUE)
  if (length(end) == 0) {
    cli::cli_abort(
      "Failed to parse per-part headers in a multipart response.",
      call = error_call
    )
  }

  headers <- curl::parse_headers(part[seq2(3L, end + 1L)])
  list(
    headers = as_headers(headers %||% character()),
    body = part[seq2(end + 4L, n)]
  )
}
