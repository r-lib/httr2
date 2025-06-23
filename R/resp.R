#' Create a HTTP response for testing
#'
#' @description
#' `response()` creates a generic response; `response_json()` creates a
#' response with a JSON body, automatically adding the correct `Content-Type`
#' header.
#'
#' Generally, you should not need to call these function directly; you'll
#' get a real HTTP response by calling [req_perform()] and friends. These
#' function is provided primarily for use in tests; if you are creating
#' responses for mocked requests, use the lower-level [new_response()].
#'
#' @inherit new_response params return
#' @export
#' @examples
#' response()
#' response(404, method = "POST")
#' response(headers = c("Content-Type: text/html", "Content-Length: 300"))
response <- function(
  status_code = 200,
  url = "https://example.com",
  method = "GET",
  headers = list(),
  body = raw(),
  timing = NULL
) {
  check_number_whole(status_code, min = 100, max = 700)
  check_string(url)
  check_string(method)

  headers <- as_headers(headers)
  # ensure we always have a date field
  if (!"date" %in% tolower(names(headers))) {
    headers$Date <- "Wed, 01 Jan 2020 00:00:00 UTC"
  }

  new_response(
    method = method,
    url = url,
    status_code = as.integer(status_code),
    headers = headers,
    body = body,
    timing = timing
  )
}

#' @export
#' @rdname response
response_json <- function(
  status_code = 200,
  url = "https://example.com",
  method = "GET",
  headers = list(),
  body = list()
) {
  headers <- as_headers(headers)
  headers$`Content-Type` <- "application/json"

  body <- charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE))

  new_response(
    method = method,
    url = url,
    status_code = as.integer(status_code),
    headers = headers,
    body = body
  )
}

#' Create a HTTP response
#'
#' This is the constructor function for the `httr2_response` S3 class. It is
#' useful primarily for mocking.
#'
#' @param method HTTP method used to retrieve the response.
#' @param url URL response came from; might not be the same as the URL in
#'   the request if there were any redirects.
#' @param status_code HTTP status code. Must be a single integer.
#' @param headers HTTP headers. Can be supplied as a raw or character vector
#'   which will be parsed using the standard rules, or a named list.
#' @param body Response, if any, contained in the response body.
#'   For `response_json()`, a R data structure to serialize to JSON.
#' @param timing A named numeric vector giving the time taken by various
#'   components.
#' @param request The [request] used to generate this response.
#' @param error_call Environment (on call stack) used in error messages.
#' @returns An HTTP response: an S3 list with class `httr2_response`.
#' @export
new_response <- function(
  method,
  url,
  status_code,
  headers,
  body,
  timing = NULL,
  request = NULL,
  error_call = caller_env()
) {
  check_string(method, call = error_call)
  check_string(url, call = error_call)
  check_number_whole(status_code, call = error_call)
  check_request(request, allow_null = TRUE, call = error_call)
  if (!is.null(timing) && !is_bare_numeric(timing)) {
    stop_input_type(
      timing,
      "a numeric vector",
      allow_null = TRUE,
      call = error_call
    )
  }
  headers <- as_headers(headers, error_call = error_call)
  if (!is.raw(body) && !is_path(body) && !inherits(body, "connection")) {
    stop_input_type(
      body,
      "a raw vector, a path, or a connection",
      call = error_call
    )
  }

  structure(
    list(
      method = method,
      url = url,
      status_code = status_code,
      headers = headers,
      body = body,
      timing = timing,
      request = request,
      cache = new_environment()
    ),
    class = "httr2_response"
  )
}

create_response <- function(req, curl_data, body) {
  the$last_response <- new_response(
    method = curl_data$method,
    url = curl_data$url,
    status_code = curl_data$status_code,
    headers = as_headers(curl_data$headers),
    body = body,
    timing = curl_data$times,
    request = req
  )

  the$last_response
}


#' @export
print.httr2_response <- function(x, ...) {
  cli::cli_text("{.cls {class(x)}}")
  cli::cli_text("{.strong {x$method}} {x$url}")
  cli::cli_text("{.field Status}: {x$status_code} {resp_status_desc(x)}")
  if (resp_header_exists(x, "Content-Type")) {
    cli::cli_text("{.field Content-Type}: {resp_content_type(x)}")
  }

  body <- x$body
  if (!resp_has_body(x)) {
    cli::cli_text("{.field Body}: None")
  } else {
    switch(
      resp_body_type(x),
      disk = cli::cli_text(
        "{.field Body}: On disk {.path {body}} ({file.size(body)} bytes)"
      ),
      memory = cli::cli_text("{.field Body}: In memory ({length(body)} bytes)"),
      stream = cli::cli_text("{.field Body}: Streaming connection")
    )
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
#' @inheritParams resp_headers
#' @returns `resp` (invisibly).
#' @export
#' @examples
#' resp <- request(example_url()) |>
#'   req_url_path("/json") |>
#'   req_perform()
#' resp |> resp_raw()
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

check_response <- function(resp, arg = caller_arg(resp), call = caller_env()) {
  if (!missing(resp) && is_response(resp)) {
    return(invisible(NULL))
  }

  stop_input_type(
    resp,
    "an HTTP response object",
    allow_null = FALSE,
    arg = arg,
    call = call
  )
}
