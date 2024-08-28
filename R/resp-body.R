#' Extract body from response
#'
#' @description
#' * `resp_body_raw()` returns the raw bytes.
#' * `resp_body_string()` returns a UTF-8 string.
#' * `resp_body_json()` returns parsed JSON.
#' * `resp_body_html()` returns parsed HTML.
#' * `resp_body_xml()` returns parsed XML.
#' * `resp_has_body()` returns `TRUE` if the response has a body.
#'
#' `resp_body_json()` and `resp_body_xml()` check that the content-type header
#' is correct; if the server returns an incorrect type you can suppress the
#' check with `check_type = FALSE`. These two functions also cache the parsed
#' object so the second and subsequent calls are low-cost.
#'
#' @param resp A response object.
#' @returns
#' * `resp_body_raw()` returns a raw vector.
#' * `resp_body_string()` returns a string.
#' * `resp_body_json()` returns NULL, an atomic vector, or list.
#' * `resp_body_html()` and `resp_body_xml()` return an `xml2::xml_document`
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

  switch(resp_body_type(resp),
    disk = readBin(resp$body, "raw", file.size(resp$body)),
    memory = resp$body,
    stream = {
      out <- read_con(resp$body)
      close(resp)
      out
    }
  )
}

#' @rdname resp_body_raw
#' @export
resp_has_body <- function(resp) {
  check_response(resp)

  switch(resp_body_type(resp),
    disk = file.size(resp$body) > 0,
    memory = length(resp$body) > 0,
    stream = isValid(resp$body)
  )
}

resp_body_type <- function(resp) {
  if (is_path(resp$body)) {
    "disk"
  } else if (inherits(resp$body, "connection")) {
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
  resp$cache[[key]] <- jsonlite::fromJSON(text, simplifyVector = simplifyVector, ...)
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

  xml2::read_html(resp$body, ...)
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

  resp$cache[[key]] <- xml2::read_xml(resp$body, ...)
  resp$cache[[key]]
}

body_cache_key <- function(prefix, ...) {
  key <- hash(list(...))
  paste0(prefix, "-", substr(key, 1, 10))
}
