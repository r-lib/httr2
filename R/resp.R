#' Create a new HTTP response
#'
#' Generally, you should not need to call this function directly; you'll
#' get a real HTTP response by calling [req_perform()] and friends. This
#' function is provided primarily for testing, and a place to describe
#' the key components of a response.
#'
#' @keywords internal
#' @param status_code HTTP status code. Must be a single integer.
#' @param url URL response came from; might not be the same as the URL in
#'   the request if there were any redirects.
#' @param method HTTP method used to retrieve the response.
#' @param headers HTTP headers. Can be supplied as a raw or character vector
#'   which will be parsed using the standard rules, or a named list.
#' @param body Response, if any, contained in the response body.
#' @returns An HTTP response: an S3 list with class `httr2_response`.
#' @export
#' @examples
#' response()
#' response(404, method = "POST")
#' response(headers = c("Content-Type: text/html", "Content-Length: 300"))
response <- function(status_code = 200,
                     url = "https://example.com",
                     method = "GET",
                     headers = list(),
                     body = raw()) {

  headers <- as_headers(headers)

  new_response(
    method = method,
    url = url,
    status_code = as.integer(status_code),
    headers = headers,
    body = body
  )
}

new_response <- function(method, url, status_code, headers, body) {
  check_string(method, "method")
  check_string(url, "url")
  check_number(status_code, "status_code")

  headers <- as_headers(headers)
  # ensure we always have a date field
  if (!"date" %in% tolower(names(headers))) {
    headers$Date <- http_date()
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
  if (resp_header_exists(x, "Content-Type")) {
    cli::cli_text("{.field Content-Type}: {resp_content_type(x)}")
  }

  body <- x$body
  if (is_path(body)) {
    cli::cli_text("{.field Body}: On disk {.path body}")
  } else if (length(body) == 0) {
    cli::cli_text("{.field Body}: Empty")
  } else if (length(body) > 0) {
    cli::cli_text("{.field Body}: In memory ({length(body)} bytes)")
  }

  invisible(x)
}

#' Show the raw response
#'
#' This function reconstructs the HTTP message that httr2 received from the
#' server. It's unlikely to be exactly byte-for-byte identical (because most
#' servers compress at least the body, and HTTP/2 can also compress the
#' headers), but it conveys the same information.
#'
#' @param resp An HTTP [response]
#' @returns `resp` (invisibly).
#' @export
#' @examples
#' resp <- request("https://httpbin.org/json") %>% req_perform()
#' resp %>% resp_raw()
resp_raw <- function(resp) {
  cli::cat_line("HTTP/1.1 ", resp$status_code, " ", resp_status_desc(resp))
  cli::cat_line(cli::style_bold(names(resp$headers)), ": ", resp$headers)
  cli::cat_line()
  if (!is.null(resp$body)) {
    cli::cat_line(resp_body_string(resp))
  }

  invisible(resp)
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
