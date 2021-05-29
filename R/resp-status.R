#' Retrieve response status
#'
#' @description
#' * `resp_status()` retrieves the numeric HTTP status code
#' * `resp_status_desc()` retrieves the brief textual description.
#' * `resp_is_error()` returns `TRUE` if the status code represents an error
#'   (i.e. a 4xx or 5xx status).
#' * `resp_check_status()` turns HTTPs errors into R errors.
#'
#' These functions are mostly for internal use because in most cases you
#' will only ever see a 200 response:
#'
#' * 1xx are handled internally by curl.
#' * 3xx redirects are automatically followed. You will only see them if you
#'   have deliberately suppressed redirects with
#'   `req %>% req_options(followlocation = FALSE)`.
#' * 4xx client and 5xx server errors are automatically turned into R errors.
#'   You can stop them from being turned into R errors with [req_error()],
#'   e.g. `req %>% req_error(is_error = ~ FALSE)`.
#'
#' @inheritParams resp_headers
#' @export
resp_status <- function(resp) {
  check_response(resp)
  resp$status_code
}

#' @export
#' @rdname resp_status
resp_status_desc <- function(resp) {
  check_response(resp)
  status <- resp_status(resp)
  if (status %in% names(http_statuses)) {
    http_statuses[[as.character(status)]]
  } else {
    NA_character_
  }
}

#' @export
#' @rdname resp_status
resp_is_error <- function(resp) {
  check_response(resp)
  resp_status(resp) >= 400
}

#' @export
#' @param info A character vector of additional information to include in
#'   the error message. Passed to [rlang::abort()].
#' @rdname resp_status
resp_check_status <- function(resp, info = NULL) {
  check_response(resp)
  if (!resp_is_error(resp)) {
    return(invisible(resp))
  }

  status <- resp_status(resp)
  desc <- resp_status_desc(resp)
  message <- glue("HTTP {status} {desc}.")

  abort(
    c(message, info),
    status = status,
    resp = resp,
    class = c(glue("httr2_http_{status}", "httr2_http"))
  )
}

http_statuses <- c(
  "100" = "Continue",
  "101" = "Switching Protocols",
  "102" = "Processing (WebDAV; RFC 2518)",
  "200" = "OK",
  "201" = "Created",
  "202" = "Accepted",
  "203" = "Non-Authoritative Information",
  "204" = "No Content",
  "205" = "Reset Content",
  "206" = "Partial Content",
  "207" = "Multi-Status (WebDAV; RFC 4918)",
  "208" = "Already Reported (WebDAV; RFC 5842)",
  "226" = "IM Used (RFC 3229)",
  "300" = "Multiple Choices",
  "301" = "Moved Permanently",
  "302" = "Found",
  "303" = "See Other",
  "304" = "Not Modified",
  "305" = "Use Proxy",
  "306" = "Switch Proxy",
  "307" = "Temporary Redirect",
  "308" = "Permanent Redirect (experimental Internet-Draft)",
  "400" = "Bad Request",
  "401" = "Unauthorized",
  "402" = "Payment Required",
  "403" = "Forbidden",
  "404" = "Not Found",
  "405" = "Method Not Allowed",
  "406" = "Not Acceptable",
  "407" = "Proxy Authentication Required",
  "408" = "Request Timeout",
  "409" = "Conflict",
  "410" = "Gone",
  "411" = "Length Required",
  "412" = "Precondition Failed",
  "413" = "Request Entity Too Large",
  "414" = "Request-URI Too Long",
  "415" = "Unsupported Media Type",
  "416" = "Requested Range Not Satisfiable",
  "417" = "Expectation Failed",
  "418" = "I'm a teapot (RFC 2324)",
  "420" = "Enhance Your Calm (Twitter)",
  "422" = "Unprocessable Entity (WebDAV; RFC 4918)",
  "423" = "Locked (WebDAV; RFC 4918)",
  "424" = "Failed Dependency (WebDAV; RFC 4918)",
  "424" = "Method Failure (WebDAV)",
  "425" = "Unordered Collection (Internet draft)",
  "426" = "Upgrade Required (RFC 2817)",
  "428" = "Precondition Required (RFC 6585)",
  "429" = "Too Many Requests (RFC 6585)",
  "431" = "Request Header Fields Too Large (RFC 6585)",
  "444" = "No Response (Nginx)",
  "449" = "Retry With (Microsoft)",
  "450" = "Blocked by Windows Parental Controls (Microsoft)",
  "451" = "Unavailable For Legal Reasons (Internet draft)",
  "499" = "Client Closed Request (Nginx)",
  "500" = "Internal Server Error",
  "501" = "Not Implemented",
  "502" = "Bad Gateway",
  "503" = "Service Unavailable",
  "504" = "Gateway Timeout",
  "505" = "HTTP Version Not Supported",
  "506" = "Variant Also Negotiates (RFC 2295)",
  "507" = "Insufficient Storage (WebDAV; RFC 4918)",
  "508" = "Loop Detected (WebDAV; RFC 5842)",
  "509" = "Bandwidth Limit Exceeded (Apache bw/limited extension)",
  "510" = "Not Extended (RFC 2774)",
  "511" = "Network Authentication Required (RFC 6585)",
  "598" = "Network read timeout error (Unknown)",
  "599" = "Network connect timeout error (Unknown)"
)
