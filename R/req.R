#' Create a new HTTP request
#'
#' To perform a HTTP request, first create a request object with `request()`,
#' then define its behaviour with `req_` functions, then perform the request
#' and fetch the response with [req_perform()].
#'
#' @param base_url Base URL for request.
#' @export
#' @examples
#' request("http://r-project.org")
request <- function(base_url) {
  new_request(base_url)
}

#' @export
print.httr2_request <- function(x, ..., redact_headers = TRUE) {
  cli::cli_text("{.cls {class(x)}}")
  method <- toupper(req_method_get(x))
  cli::cli_text("{.strong {method}} {x$url}")

  bullets_with_header("Headers:", headers_redact(x$headers, redact_headers))
  cli::cli_text("{.strong Body}: {req_body_info(x)}")
  bullets_with_header("Options:", x$options)
  bullets_with_header("Policies:", x$policies)

  invisible(x)
}

new_request <- function(url, method = NULL, headers = list(), body = NULL, fields = list(), options = list(), policies = list()) {
  if (!is_string(url)) {
    abort("`url` must be a string")
  }

  structure(
    list(
      url = url,
      method = method,
      headers = headers,
      body = body,
      fields = fields,
      options = options,
      policies = policies
    ),
    class = "httr2_request"
  )
}

is_request <- function(x) {
  inherits(x, "httr2_request")
}

check_request <- function(req) {
  if (is_request(req)) {
    return()
  }
  abort("`req` must be an HTTP request object")
}
