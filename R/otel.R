# Attaches an Open Telemetry span that abides by the semantic conventions for
# HTTP clients to the request, including the associated W3C trace context
# headers.
#
# See: https://opentelemetry.io/docs/specs/semconv/http/http-spans/#http-client-span
req_with_span <- function(
  req,
  resend_count = 0,
  tracer = default_tracer(),
  scope = parent.frame()
) {
  if (is.null(tracer) || !tracer$is_enabled()) {
    return(req)
  }
  parsed <- tryCatch(url_parse(req$url), error = function(cnd) NULL)
  if (is.null(parsed)) {
    # Don't create spans for invalid URLs.
    return(req)
  }
  if (!req_has_user_agent(req)) {
    req <- req_user_agent(req)
  }
  default_port <- 443L
  if (parsed$scheme == "http") {
    default_port <- 80L
  }
  # Follow the semantic conventions and redact credentials in the URL, when
  # present.
  if (!is.null(parsed$username)) {
    parsed$username <- "REDACTED"
  }
  if (!is.null(parsed$password)) {
    parsed$password <- "REDACTED"
  }
  method <- req_method_get(req)
  span <- tracer$start_span(
    name = method,
    options = list(kind = "CLIENT"),
    # Ensure we set attributes relevant to sampling at span creation time.
    attributes = compact(list(
      "http.request.method" = method,
      "server.address" = parsed$hostname,
      "server.port" = parsed$port %||% default_port,
      "url.full" = url_build(parsed),
      "http.request.resend_count" = if (resend_count > 1) resend_count,
      "user_agent.original" = req$options$useragent
    )),
    scope = scope
  )
  ctx <- span$get_context()
  req <- req_headers(req, !!!ctx$to_http_headers())
  req$state$span <- span
  req
}

# Ends the Open Telemetry span associated with this request, if any.
req_end_span <- function(req, resp = NULL) {
  span <- req$state$span
  if (is.null(span) || !span$is_recording()) {
    return()
  }
  if (is.null(resp)) {
    span$end()
    return()
  }
  if (is_error(resp)) {
    span$record_exception(resp)
    span$set_status("error")
    # Surface the underlying curl error class.
    span$set_attribute("error.type", class(resp$parent)[1])
    span$end()
    return()
  }
  span$set_attribute("http.response.status_code", resp_status(resp))
  if (error_is_error(req, resp)) {
    desc <- resp_status_desc(resp)
    if (is.na(desc)) {
      desc <- NULL
    }
    span$set_status("error", desc)
    # The semantic conventions recommend using the status code as a string for
    # these cases.
    span$set_attribute("error.type", as.character(resp_status(resp)))
  } else {
    span$set_status("ok")
  }
  span$end()
}

# Replaces the existing Open Telemetry span on a request with a new one. Used
# for retries.
req_reset_span <- function(
  req,
  handle,
  resend_count = 0,
  tracer = default_tracer(),
  scope = parent.frame()
) {
  req <- req_with_span(req, resend_count, tracer, scope)
  if (is.null(req$state$span)) {
    return(req)
  }
  # Because the headers have changed, we need to re-sign the request and update
  # stateful components (like the handle).
  req <- auth_sign(req)
  curl::handle_setheaders(handle, .list = headers_flatten(req$headers))
  req$state$headers <- req$headers
  req
}

default_tracer <- function() {
  if (!is_installed("otel")) {
    return(NULL)
  }
  otel::get_tracer("httr2")
}
