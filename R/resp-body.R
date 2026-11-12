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

extract_multipart_boundary <- function(content_type) {
  allowed <- "0-9a-zA-Z'()+_,-./:=?"
  boundary <- sub(paste0("multipart/.*; *boundary=([", allowed, " ]+[", allowed, "]).*"), "\\1", content_type)
  if (boundary == content_type) {
    cli::cli_abort("Failed to extract multipart boundary from content type {.str {content_type}}.")
  }
  boundary
}

#' @rdname resp_body_raw
#' @export
resp_body_multipart <- function(resp, check_type = TRUE, ...) {
  check_response(resp)

  # Need to support multiple subtypes (alternative, mixed, digest, byteranges, etc.)
  # and I don't want to list out all type combinations in check_content_type.
  ctype <- resp_content_type(resp)
  if (check_type && parse_content_type(ctype)$type != "multipart") {
    cli::cli_abort("Unexpected content type {.str {ctype}}.")
  }

  # See https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html for the allowed boundary.
  # Note that spaces are allowed inside the boundary string, but not at the end of it.
  boundary <- extract_multipart_boundary(resp_header(resp, "Content-Type"))
  body <- resp_body_raw(resp)

  cr <- charToRaw("\r")
  lf <- charToRaw("\n")
  dash <- charToRaw("-")

  # I'd prefer to avoid creating a (possibly very long) string from the body.
  # So, instead of using regexes, we'll manually scan the raw body to find CRLFs and boundaries.
  delim_prefix <- c(cr, lf, dash, dash, charToRaw(boundary))
  pos_pre <- which(body == delim_prefix[1L])
  for (i in 2:length(delim_prefix)) {
    pos_pre <- pos_pre[body[pos_pre + 1L] == delim_prefix[i]] + 1L
  }

  pos_end <- pos_pre[body[pos_pre + 1L] == dash] + 1L
  pos_end <- pos_end[body[pos_end + 1L] == dash] + 1L
  if (length(pos_end) == 0) {
    cli::cli_abort("No closing delimiter detected in multipart response body.")
  }
  pos_end <- pos_end[1]

  pos_mid <- pos_pre[body[pos_pre + 1] == cr] + 1L
  pos_mid <- pos_mid[body[pos_mid + 1] == lf] + 1L
  pos_mid <- pos_mid[pos_mid < pos_end]
  if (length(pos_mid) == 0) {
    cli::cli_abort("No non-closing delimiters detected in multipart response body.")
  }

  output <- vector("list", length(pos_mid))
  for (i in seq_along(pos_mid)) {
    part_start <- pos_mid[i] + 1L # first position after the delimiter
    if (i == length(pos_mid)) {
      part_end <- pos_end
    } else {
      part_end <- pos_mid[i + 1]
    }
    part_end <- part_end - length(delim_prefix) - 2L # last position before the delimiter

    if (part_start > part_end) {
      cli::cli_abort("Part is too short to be parsed in multipart response body.")
    }
    part <- body[part_start:part_end]

    # Finding the first empty newline to separate the part's body from headers.
    pos_empty <- which(part == cr)
    pos_empty <- pos_empty[part[pos_empty + 1L] == lf] + 1L
    if (length(pos_empty) == 0) {
      cli::cli_abort("Failed to parse per-part headers in a multipart response.")
    }

    if (pos_empty[1] == 2) {
      # No headers, i.e., empty line is at the start.
      headers <- list()
      past_header <- 3
    } else {
      # First empty line is represented by a double CRLF.
      pos_empty <- pos_empty[part[pos_empty + 1] == cr] + 1L
      pos_empty <- pos_empty[part[pos_empty + 1] == lf] + 1L
      if (length(pos_empty) == 0) {
        cli::cli_abort("Failed to parse per-part headers in a multipart response.")
      }
      first_crlf <- pos_empty[1]
      headers <- curl::parse_headers(part[1:(first_crlf - 4)])
      past_header <- first_crlf + 1L
    }
    if (past_header <= length(part)) {
      part <- part[past_header:length(part)]
    } else {
      part <- raw()
    }

    # Using the original response's values to fill in the per-part response.
    output[[i]] <- new_response(resp$method, resp$url, resp$status_code, headers = headers, body = part)
  }

  output
}
