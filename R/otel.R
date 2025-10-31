otel_tracer_name <- "org.r-lib.httr2"
otel_tracer <- NULL
otel_is_tracing <- FALSE

# Attaches an Open Telemetry span that abides by the semantic conventions for
# HTTP clients to the request, including the associated W3C trace context
# headers.
#
# See: https://opentelemetry.io/docs/specs/semconv/http/http-spans/#http-client-span
req_with_span <- function(
  req,
  resend_count = 0,
  tracer = otel_tracer,
  activation_scope = parent.frame(),
  activate = TRUE
) {
  if (!tracer_enabled(tracer)) {
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

otel_cache_tracer <- function() {
  requireNamespace("otel", quietly = TRUE) || return()
  otel_tracer <<- otel::get_tracer(otel_tracer_name)
  otel_is_tracing <<- tracer_enabled(otel_tracer)
}

tracer_enabled <- function(tracer) {
  .subset2(tracer, "is_enabled")()
}

otel_refresh_tracer <- function(pkgname) {
  requireNamespace("otel", quietly = TRUE) || return()
  ns <- getNamespace(pkgname)
  do.call(unlockBinding, list("otel_is_tracing", ns)) # do.call for R CMD Check
  do.call(unlockBinding, list("otel_tracer", ns))
  otel_tracer <- otel::get_tracer()
  ns[["otel_is_tracing"]] <- tracer_enabled(otel_tracer)
  ns[["otel_tracer"]] <- otel_tracer
  lockBinding("otel_is_tracing", ns)
  lockBinding("otel_tracer", ns)
}
