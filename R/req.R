#' Create a new HTTP request
#'
#' @description
#' There are three steps needed to perform a HTTP request with httr2:
#'
#' 1. Create a request object with `request(url)` (this function).
#' 2. Define its behaviour with `req_` functions, e.g.:
#'    * [req_headers()] to set header values.
#'    * [req_url()] and friends to modify the url.
#'    * [req_body_json()] and friends to add a body.
#'    * [req_auth_basic()] to perform basic HTTP authentication.
#'    * [req_oauth_auth_code()] to use the OAuth auth code flow.
#' 3. Perform the request and fetch the response with [req_perform()].
#'
#' @param base_url Base URL for request.
#' @returns An HTTP request: an S3 list with class `httr2_request`.
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

  bullets_with_header("Headers:", headers_flatten(headers_redact(x$headers, redact_headers)))
  cli::cli_text("{.strong Body}: {req_body_info(x)}")
  bullets_with_header("Options:", x$options)
  bullets_with_header("Policies:", x$policies)

  invisible(x)
}

new_request <- function(url,
                        method = NULL,
                        headers = list(),
                        body = NULL,
                        fields = list(),
                        options = list(),
                        policies = list(),
                        error_call = caller_env()) {
  check_string(url, call = error_call)

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

check_request <- function(req,
                          arg = caller_arg(req),
                          call = caller_env(),
                          allow_null = FALSE) {
  if (!missing(req)) {
    if (is_request(req)) {
      return(invisible(NULL))
    }

    if (allow_null && is.null(req)) {
      return(invisible(NULL))
    }
  }

  stop_input_type(
    req,
    "an HTTP request object",
    allow_null = allow_null,
    arg = arg,
    call = call
  )
}
