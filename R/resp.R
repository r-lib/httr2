new_response <- function(method, url, status_code, headers, body, times) {
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

response <- function(status_code,
                     url = NULL,
                     method = "GET",
                     headers = list(),
                     body = NULL) {
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
