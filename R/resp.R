#' Create a new HTTP response
#'
#' Generally, you should not need to call this function directly; you'll
#' get a real HTTP response by calling [req_fetch()] and friends. This
#' function is provided primarily for testing, and a place to describe
#' the key components of a response.
#'
#' @keywords internal
#' @param status_code HTTP status code. Must be a single integer.
#' @param url URL response came from; might not be the same as the URL in
#'   the request if there were any redirects.
#' @param method HTTP method used to retrieve the response.
#' @param headers A list of HTTP headers.
#' @param body Response, if any, contained in the response body.
#' @export
#' @examples
#' response()
#' response(404, method = "POST")
response <- function(status_code = 200,
                     url = "http://example.com",
                     method = "GET",
                     headers = list(),
                     body = NULL) {

  if (is.character(headers)) {
    headers <- curl::parse_headers_list(headers)
  }

  new_response(
    method = method,
    url = url,
    status_code = as.integer(status_code),
    headers = headers,
    body = body
  )
}

new_response <- function(method, url, status_code, headers, body, times) {
  check_string(method, "method")
  check_string(url, "url")
  check_number(status_code, "status_code")

  if (!is_list(headers) || !(length(headers) == 0 || is_named(headers))) {
    abort("`headers` must be a named list")
  }
  # ensure we always have a date field
  if (!has_name(headers, "date")) {
    headers$date <- httr::http_date(Sys.time())
  }

  structure(
    list(
      method = method,
      url = url,
      status_code = status_code,
      headers = headers,
      body = body
    ),
    class = "httr2_response"
  )
}


#' @export
print.httr2_response <- function(x,...) {
  cli::cli_text("{.cls {class(x)}}")
  cli::cli_text("{.strong {x$method}} {x$url}")
  cli::cli_text("{.field Status}: {x$status_code} {resp_status_desc(x)}")
  cli::cli_text("{.field Content-Type}: {resp_content_type(x)}")

  body <- x$body
  if (is.null(body)) {
    cli::cli_text("{.field Body}: Empty")
  } else if (is_path(body)) {
    cli::cli_text("{.field Body}: On disk {.path body}")
  } else if (length(body) > 0) {
    cli::cli_text("{.field Body}: In memory ({length(body)} bytes)")
  }

  invisible(x)
}

is_response <- function(x) {
  inherits(x, "httr2_response")
}
check_response <- function(req) {
  if (is_response(req)) {
    return()
  }
  abort("`resp` must be an HTTP response object")
}
