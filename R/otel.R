# Attaches an Open Telemetry span that abides by the semantic conventions for
# HTTP clients to the request, including the associated W3C trace context
# headers.
#
# See: https://opentelemetry.io/docs/specs/semconv/http/http-spans/#http-client-span
req_with_span <- function(
  req,
  resend_count = 0,
  tracer = get_tracer(),
  activation_scope = parent.frame(),
  activate = TRUE
) {
  if (!is_tracing(tracer)) {
    cli::cli_abort(
      "Cannot create request span; tracing is not enabled",
      .internal = TRUE
    )
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
  method <- req_get_method(req)
  # Set required (and some recommended) attributes, especially those relevant to
  # sampling at span creation time.
  attributes <- compact(list(
    "http.request.method" = method,
    "server.address" = parsed$hostname,
    "server.port" = parsed$port %||% default_port,
    "url.full" = url_build(parsed),
    "http.request.resend_count" = if (resend_count > 1) resend_count,
    "user_agent.original" = req$options$useragent
  ))
  span <- tracer$start_span(
    name = method,
    options = list(kind = "CLIENT"),
    attributes = attributes
  )
  if (activate) {
    span$activate(activation_scope, end_on_exit = TRUE)
  }
  req <- req_headers(req, !!!otel::pack_http_context())
  req$state$span <- span
  req
}

req_record_span_status <- function(req, resp = NULL) {
  span <- req$state$span
  if (is.null(span) || !span$is_recording()) {
    return()
  }
  # For more accurate span timing, we end the span after the response has been
  # received, rather than at the end of the associated scope.
  on.exit(span$end())
  if (is.null(resp)) {
    return()
  }
  if (is_error(resp)) {
    span$record_exception(resp)
    span$set_status("error")
    # Surface the underlying curl error class.
    span$set_attribute("error.type", class(resp$parent)[1])
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
}

get_tracer <- function() {
  if (!is.null(the$tracer)) {
    return(the$tracer)
  }
  if (!is_installed("otel")) {
    return(NULL)
  }
  if (is_testing()) {
    # Don't cache the tracer in unit tests. It interferes with tracer provider
    # injection in otelsdk::with_otel_record().
    return(otel::get_tracer("httr2"))
  }
  the$tracer <- otel::get_tracer("httr2")
  the$tracer
}

is_tracing <- function(tracer = get_tracer()) {
  !is.null(tracer) && tracer$is_enabled()
}
