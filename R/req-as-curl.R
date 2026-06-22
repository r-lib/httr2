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

  body <- curl_body(req, obfuscated)
  args <- c(
    dquote(req_get_url(req)),
    curl_method(req, has_body = !is.null(body)),
    curl_headers(req, obfuscated),
    curl_options(req),
    body
  )
  indent <- c("", rep("  ", length(args) - 1))
  backslash <- c(rep(" \\", length(args) - 1), "")
  out <- paste0("curl ", paste0(indent, args, backslash, collapse = "\n"))

  structure(out, class = "httr2_cmd")
}

curl_method <- function(req, has_body = FALSE) {
  method <- req_get_method(req)
  if (method == "GET" || (method == "POST" && has_body)) {
    NULL
  } else if (method == "HEAD") {
    "--head"
  } else {
    paste0("--request ", method)
  }
}

curl_headers <- function(req, obfuscated = c("redact", "reveal")) {
  obfuscated <- arg_match(obfuscated)

  headers <- req_get_headers(req, redacted = obfuscated)
  if (is_empty(headers)) {
    return(NULL)
  }
  paste0("--header ", dquote(paste0(names(headers), ": ", unlist(headers))))
}

curl_options <- function(req) {
  options <- req$options

  known_options <- c(
    "timeout_ms", # req_timeout()
    "connecttimeout", # req_timeout()
    "proxy", # req_proxy()
    "proxyport", # req_proxy()
    "proxyuserpwd", # req_proxy()
    "useragent", # req_user_agent()
    "followlocation",
    "verbose", # req_verbose()
    "cookiejar", # req_cookie_preserve()
    "cookiefile", # req_cookie_preserve()
    "cookie" # req_cookies_set()
  )
  # R callbacks and the like, with no command line equivalent
  ignored_options <- c(
    "debugfunction", # req_verbose()
    "xferinfofunction", # req_progress()
    "noprogress", # req_progress()
    "proxyauth", # req_proxy()
    "forbid_reuse" # req_verbose_test()
  )
  unknown <- setdiff(names(options), c(known_options, ignored_options))
  if (length(unknown) > 0) {
    cli::cli_warn("Can't translate option{?s} {.val {unknown}}.")
  }

  args <- lapply(names(options), function(name) {
    value <- options[[name]]
    switch(
      name,
      timeout_ms = paste0("--max-time ", value / 1000),
      connecttimeout = paste0("--connect-timeout ", value),
      proxy = {
        host <- value
        if (!is.null(options$proxyport)) {
          host <- paste0(host, ":", options$proxyport)
        }
        paste0("--proxy ", dquote(host))
      },
      proxyuserpwd = paste0("--proxy-user ", dquote(value)),
      useragent = paste0("--user-agent ", dquote(value)),
      verbose = if (value) "--verbose",
      cookiejar = paste0("--cookie-jar ", dquote(value)),
      cookiefile = paste0("--cookie ", dquote(value)),
      cookie = paste0("--cookie ", dquote(value))
    )
  })

  # httr2 follows redirects by default, but command line curl doesn't
  follow <- if (!isFALSE(options$followlocation)) "--location"

  c(follow, unlist(args))
}

curl_body <- function(req, obfuscated = c("redact", "reveal")) {
  obfuscated <- arg_match(obfuscated)

  body <- req_get_body(req, obfuscated = obfuscated)
  if (is.null(body)) {
    return(NULL)
  }
  type <- req_get_body_type(req)

  c(curl_content_type(req, type), curl_body_data(body, type))
}

# Skip if Content-Type is already set as a header
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
  paste0("--header ", dquote(paste0("Content-Type: ", content_type)))
}

curl_body_data <- function(body, type) {
  switch(
    type,
    string = paste0("--data ", dquote(gsub('"', '\\"', body))),
    # raw bodies are read from stdin
    raw = paste0("--data-binary ", dquote("@-")),
    file = paste0("--data-binary ", dquote(paste0("@", body))),
    json = paste0("--data '", jsonlite::toJSON(body, auto_unbox = TRUE), "'"),
    form = paste0(
      "--data ",
      dquote(paste(names(body), unlist(body), sep = "=", collapse = "&"))
    ),
    multipart = paste0(
      "--form ",
      dquote(paste0(names(body), "=", unlist(body)))
    )
  )
}

dquote <- function(x) {
  ifelse(grepl("[^A-Za-z0-9._~:/@%+=,-]", x), paste0('"', x, '"'), x)
}
