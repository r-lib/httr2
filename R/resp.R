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
