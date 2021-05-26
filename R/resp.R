

new_response <- function(handle, method, url, status_code, headers, body, times) {
  structure(
    list(
      handle = handle,
      method = method,
      url = url,
      status_code = status_code,
      headers = headers,
      body = body,
      times = times
    ),
    class = "httr2_response"
  )
}

#' @export
print.httr2_response <- function(x, ...) {
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
