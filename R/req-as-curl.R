#' Translate an httr2 request to a curl command
#'
#' Convert an httr2 request object to the equivalent curl command line call.
#' This is useful for debugging, for sharing a request with someone who doesn't
#' use R, or for handing off to another tool.
#'
#' @inheritParams req_perform
#' @inheritParams req_get_body
#' @return A string containing the curl command, with class `httr2_cmd` so
#'   it prints nicely.
#' @seealso [curl_translate()] to translate in the other direction.
#' @export
#' @examples
#' # Basic GET request
#' request("https://httpbin.org/get") |>
#'   req_as_curl()
#'
#' # POST with JSON body
#' request("https://httpbin.org/post") |>
#'   req_body_json(list(name = "value")) |>
#'   req_as_curl()
#'
#' # Secrets are redacted by default, but can be revealed
#' request("https://example.com") |>
#'   req_headers_redacted(Authorization = "secret") |>
#'   req_as_curl(obfuscated = "reveal")
req_as_curl <- function(req, obfuscated = c("redact", "reveal")) {
  check_request(req)
  obfuscated <- arg_match(obfuscated)

  args <- c(
    req_method_as_curl(req),
    req_headers_as_curl(req, obfuscated),
    req_options_as_curl(req),
    req_body_as_curl(req, obfuscated)
  )
  out <- curl_command(args, req_get_url(req))
  structure(out, class = "httr2_cmd")
}

req_method_as_curl <- function(req) {
  method <- req_get_method(req)
  # curl uses GET by default, so it only needs to be requested explicitly
  if (method == "GET") {
    return(NULL)
  }
  paste0("-X ", method)
}

req_headers_as_curl <- function(req, obfuscated = c("redact", "reveal")) {
  obfuscated <- arg_match(obfuscated)

  headers <- req_get_headers(req, redacted = obfuscated)
  if (is_empty(headers)) {
    return(NULL)
  }
  paste0("-H ", dquote(paste0(names(headers), ": ", unlist(headers))))
}

req_options_as_curl <- function(req) {
  options <- req$options

  # There's no programmatic mapping between libcurl's option names and the
  # curl command line flags, so each supported option is translated by hand.
  # TODO: replace with a `req_get_options()` introspection helper.
  known_options <- c(
    "timeout",
    "connecttimeout",
    "proxy",
    "useragent",
    "referer",
    "followlocation",
    "verbose",
    "cookiejar",
    "cookiefile"
  )
  unknown <- setdiff(names(options), known_options)
  if (length(unknown) > 0) {
    cli::cli_warn("Can't translate option{?s} {.val {unknown}}.")
  }

  args <- lapply(names(options), function(name) {
    value <- options[[name]]
    switch(
      name,
      timeout = paste0("--max-time ", value), # req_timeout()
      connecttimeout = paste0("--connect-timeout ", value),
      proxy = paste0("--proxy ", value), # req_proxy()
      useragent = paste0("--user-agent ", dquote(value)), # req_user_agent()
      referer = paste0("--referer ", dquote(value)),
      followlocation = if (value) "--location", # httr2 follows redirects
      verbose = if (value) "--verbose", # req_verbose()
      # req_cookie_preserve() and req_cookies_set()
      cookiejar = paste0("--cookie-jar ", dquote(value)),
      cookiefile = paste0("--cookie ", dquote(value))
    )
  })
  unlist(args)
}

req_body_as_curl <- function(req, obfuscated = c("redact", "reveal")) {
  obfuscated <- arg_match(obfuscated)

  body <- req_get_body(req, obfuscated = obfuscated)
  if (is.null(body)) {
    return(NULL)
  }
  type <- req_get_body_type(req)

  c(curl_content_type(req, type), curl_body_data(body, type))
}

# Emit a `Content-Type` header for the body, unless one is already set as a
# request header (in which case it's emitted by `req_headers_as_curl()`).
curl_content_type <- function(req, type) {
  if ("content-type" %in% tolower(names(req_get_headers(req)))) {
    return(NULL)
  }

  content_type <- req$body$content_type %||%
    switch(
      type,
      json = "application/json",
      form = "application/x-www-form-urlencoded"
    )
  if (is.null(content_type) || !nzchar(content_type)) {
    return(NULL)
  }
  paste0("-H ", dquote(paste0("Content-Type: ", content_type)))
}

curl_body_data <- function(body, type) {
  switch(
    type,
    string = paste0("-d ", dquote(gsub('"', '\\"', body))),
    # raw bodies come from a connection, so read the data from stdin
    raw = paste0("--data-binary ", dquote("@-")),
    file = paste0("--data-binary ", dquote(paste0("@", body))),
    json = paste0("-d '", jsonlite::toJSON(body, auto_unbox = TRUE), "'"),
    form = paste0(
      "-d ",
      dquote(paste(names(body), unlist(body), sep = "=", collapse = "&"))
    ),
    multipart = paste0("-F ", dquote(paste0(names(body), "=", unlist(body))))
  )
}

# Assemble curl arguments into a command, placing each argument on its own
# line continued with a trailing backslash, e.g.
#   curl -X POST \
#     -H "Accept: application/json" \
#     "https://example.com"
curl_command <- function(args, url) {
  args <- c(args, dquote(url))

  indent <- c("", rep("  ", length(args) - 1))
  backslash <- c(rep(" \\", length(args) - 1), "")
  paste0("curl ", paste0(indent, args, backslash, collapse = "\n"))
}

dquote <- function(x) {
  paste0('"', x, '"')
}
