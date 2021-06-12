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
    c(message, resp_auth_message(resp), info),
    status = status,
    resp = resp,
    class = c(glue("httr2_http_{status}"), "httr2_http")
  )
}

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
http_statuses <- c(
  "100" = "Continue",
  "101" = "Switching Protocols",
  "102" = "Processing",
  "103" = "Early Hints",
  "200" = "OK",
  "201" = "Created",
  "202" = "Accepted",
  "203" = "Non-Authoritative Information",
  "204" = "No Content",
  "205" = "Reset Content",
  "206" = "Partial Content",
  "207" = "Multi-Status",
  "208" = "Already Reported",
  "226" = "IM Used",
  "300" = "Multiple Choice",
  "301" = "Moved Permanently",
  "302" = "Found",
  "303" = "See Other",
  "304" = "Not Modified",
  "305" = "Use Proxy",
  "307" = "Temporary Redirect",
  "308" = "Permanent Redirect",
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
  "413" = "Payload Too Large",
  "414" = "URI Too Long",
  "415" = "Unsupported Media Type",
  "416" = "Range Not Satisfiable",
  "417" = "Expectation Failed",
  "418" = "I'm a teapot",
  "421" = "Misdirected Request",
  "422" = "Unprocessable Entity",
  "423" = "Locked",
  "424" = "Failed Dependency",
  "425" = "Too Early",
  "426" = "Upgrade Required",
  "428" = "Precondition Required",
  "429" = "Too Many Requests",
  "451" = "Unavailable For Legal Reasons",
  "500" = "Internal Server Error",
  "501" = "Not Implemented",
  "502" = "Bad Gateway",
  "503" = "Service Unavailable",
  "504" = "Gateway Timeout",
  "505" = "HTTP Version Not Supported",
  "506" = "Variant Also Negotiates",
  "507" = "Insufficient Storage",
  "508" = "Loop Detected",
  "510" = "Not Extended",
  "511" = "Network Authentication Required"
)


resp_auth_message <- function(resp) {
  # https://datatracker.ietf.org/doc/html/rfc6750#page-9
  www_auth <- resp_header(resp, "WWW-Authenticate")
  if (is.null(www_auth)) {
    return(NULL)
  }

  www_auth <- parse_www_authenticate(www_auth)
  params <- www_auth$params
  if (www_auth$scheme != "Bearer") {
    return(NULL)
  }

  if (has_name(params, "error")) {
    msg <- glue("OAuth error: {params$error}")
    if (has_name(params, "error_description")) {
      msg <- paste0(msg, " - ", params$error_description)
    }
  } else {
    msg <- "OAuth error"
  }

  non_error <- params[!grepl("^error", names(params))]
  msg <- c(msg, paste0(names(non_error), ": ", non_error))
  msg
}

parse_www_authenticate <- function(x) {
  pieces_m <- regexpr(" ", x, fixed = TRUE)
  pieces <- regmatches(x, pieces_m, invert = TRUE)[[1]]

  # Use scan to deal with quoted strings. It loses the quotes, but it's
  # ok because the field name can't be a quoted string so there's no ambiguity
  # about who the = belongs to.
  params <- scan(text = pieces[[2]], what = character(), sep = ",", quiet = TRUE, quote = '"')

  equals <- regexpr("=", params, fixed = TRUE)
  param_pieces <- regmatches(params, equals, invert = TRUE)
  param_pieces <- param_pieces[lengths(param_pieces) == 2]

  param_val <- trimws(map_chr(param_pieces, "[[", 2))
  param_name <- trimws(map_chr(param_pieces, "[[", 1))

  list(
    scheme = pieces[[1]],
    params = set_names(as.list(param_val), param_name)
  )
}
