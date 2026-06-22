#' Translate an httr2 request to a curl command
#'
#' Convert an httr2 request object to an approximate curl command line call.
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

  req <- req_prepare(req)
  req <- auth_sign(req)

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
  out <- paste0(
    curl_body_input(req),
    "curl ",
    paste0(indent, args, backslash, collapse = "\n")
  )

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
    "cookie", # req_cookies_set()
    "proxyauth",
    "ssl_verifypeer",
    "ssl_verifyhost",
    "ssl_verifystatus",
    "cainfo",
    "capath",
    "sslcert",
    "sslkey",
    "keypasswd",
    "pinnedpublickey",
    "userpwd",
    "httpauth",
    "failonerror",
    "maxredirs",
    "interface",
    "low_speed_limit",
    "low_speed_time",
    "accept_encoding"
  )
  # R callbacks and the like, with no command line equivalent
  ignored_options <- c(
    "debugfunction", # req_verbose()
    "xferinfofunction", # req_progress()
    "noprogress", # req_progress()
    "forbid_reuse", # req_verbose_test()
    "nobody", # req_method_apply()
    "customrequest", # req_method_apply()
    "post", # req_body_apply()
    "postfieldsize", # req_body_apply()
    "postfields", # req_body_apply()
    "readfunction", # req_body_apply()
    "seekfunction", # req_body_apply()
    "postfieldsize_large" # req_body_apply()
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
      proxyauth = curl_auth_option(value, proxy = TRUE),
      useragent = paste0("--user-agent ", dquote(value)),
      verbose = if (value) "--verbose",
      cookiejar = paste0("--cookie-jar ", dquote(value)),
      cookiefile = paste0("--cookie ", dquote(value)),
      cookie = paste0("--cookie ", dquote(value)),
      ssl_verifypeer = ,
      ssl_verifyhost = NULL,
      ssl_verifystatus = if (value) "--cert-status",
      cainfo = paste0("--cacert ", dquote(value)),
      capath = paste0("--capath ", dquote(value)),
      sslcert = paste0("--cert ", dquote(value)),
      sslkey = paste0("--key ", dquote(value)),
      keypasswd = paste0("--pass ", dquote(value)),
      pinnedpublickey = paste0("--pinnedpubkey ", dquote(value)),
      userpwd = paste0("--user ", dquote(value)),
      httpauth = curl_auth_option(value),
      failonerror = if (value) "--fail",
      maxredirs = paste0("--max-redirs ", value),
      interface = paste0("--interface ", dquote(value)),
      low_speed_limit = paste0("--speed-limit ", value),
      low_speed_time = paste0("--speed-time ", value),
      accept_encoding = c(
        if (nzchar(value)) {
          paste0("--header ", dquote(paste0("Accept-Encoding: ", value)))
        },
        "--compressed"
      )
    )
  })

  # httr2 follows redirects by default, but command line curl doesn't
  follow <- if (!isFALSE(options$followlocation)) "--location"
  insecure <- if (
    curl_option_false(options$ssl_verifypeer) ||
      curl_option_false(options$ssl_verifyhost)
  ) {
    "--insecure"
  }

  c(follow, insecure, unlist(args))
}

curl_option_false <- function(value) {
  !is.null(value) &&
    length(value) == 1 &&
    !is.na(value) &&
    !as.logical(value)
}

curl_auth_option <- function(value, proxy = FALSE) {
  flags <- c(
    `1` = "basic",
    `2` = "digest",
    `4` = "negotiate",
    `8` = "ntlm",
    `16` = "digest",
    `-17` = "anyauth"
  )
  auth <- unname(flags[as.character(value)])
  if (length(auth) != 1 || is.na(auth)) {
    cli::cli_warn("Can't translate authentication bitmask {.val {value}}.")
    return(NULL)
  }

  paste0("--", if (proxy) "proxy-", auth)
}

curl_body <- function(req, obfuscated = c("redact", "reveal")) {
  obfuscated <- arg_match(obfuscated)

  body <- req_get_body(req, obfuscated = obfuscated)
  if (is.null(body)) {
    return(NULL)
  }
  type <- req_get_body_type(req)

  c(
    curl_content_type(req, type),
    curl_body_data(body, type, params = req$body$params)
  )
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

curl_body_data <- function(body, type, params = list(auto_unbox = TRUE)) {
  switch(
    type,
    string = paste0("--data ", dquote(body)),
    raw = "--data-binary @-",
    file = paste0("--data-binary ", dquote(paste0("@", body))),
    json = paste0(
      "--data ",
      dquote(exec(jsonlite::toJSON, body, !!!params))
    ),
    form = paste0(
      "--data ",
      dquote(url_query_build(body))
    ),
    multipart = curl_body_multipart(body)
  )
}

curl_body_multipart <- function(body) {
  unlist(Map(curl_body_multipart_field, names(body), body), use.names = FALSE)
}

curl_body_multipart_field <- function(name, value) {
  if (inherits(value, "form_file")) {
    spec <- paste0(name, "=@", curl_form_quote(value$path))
    if (!is.null(value$type)) {
      spec <- paste0(spec, ";type=", value$type)
    }
    if (!is.null(value$name)) {
      spec <- paste0(spec, ";filename=", curl_form_quote(value$name))
    }
    paste0("--form ", dquote(spec))
  } else if (inherits(value, "form_data")) {
    type <- value$type
    value <- rawToChar(value$value)
    if (is.null(type)) {
      paste0("--form-string ", dquote(paste0(name, "=", value)))
    } else {
      spec <- paste0(name, "=", curl_form_quote(value), ";type=", type)
      paste0("--form ", dquote(spec))
    }
  } else {
    paste0("--form-string ", dquote(paste0(name, "=", value)))
  }
}

curl_form_quote <- function(x) {
  paste0('"', gsub('(["\\\\])', "\\\\\\1", x), '"')
}

curl_body_input <- function(req) {
  if (req_get_body_type(req) != "raw") {
    return("")
  }

  encoded <- openssl::base64_encode(req_get_body(req))
  paste0("printf %s ", dquote(encoded), " | base64 --decode | ")
}

dquote <- function(x) {
  ifelse(
    grepl("[^A-Za-z0-9._~:/@%+=,-]", x),
    paste0("'", gsub("'", "'\"'\"'", x, fixed = TRUE), "'"),
    x
  )
}
