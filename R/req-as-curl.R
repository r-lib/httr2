#' Translate an httr2 request to a curl command
#'
#' Convert an httr2 request object to equivalent curl command line syntax.
#' This is useful for debugging, sharing requests, or converting to other tools.
#'
#' @inheritParams req_perform
#' @return A character string containing the curl command.
#' @export
#' @examples
#' @seealso [curl_translate()]
#' \dontrun{
#' # Basic GET request
#' request("https://httpbin.org/get") |>
#'   req_as_curl()
#'
#' # POST with JSON body
#' request("https://httpbin.org/post") |>
#'   req_body_json(list(name = "value")) |>
#'   req_as_curl()
#'
#' # POST with form data
#' request("https://httpbin.org/post") |>
#'   req_body_form(name = "value") |>
#'   req_as_curl()
#' }
req_as_curl <- function(req) {
  # validate the request
  check_request(req)

  # Extract URL
  url <- req_get_url(req)

  # use the request's method if it is set, otherwise infer
  method <- req$method %||%
    {
      if (!is.null(req$body$data)) {
        "POST"
      } else {
        "GET"
      }
    }

  # we will append to cmd_args to build up the request
  cmd_args <- c()

  # if the method isn't GET, it needs to be specified with `-X`
  if (method != "GET") {
    cmd_args <- c(cmd_args, paste0("-X ", method))
  }

  # get headers and reveal obfuscated values
  headers <- req_get_headers(req, redacted = "reveal")

  # if headers are present, add them using -H flag
  if (!rlang::is_empty(headers)) {
    for (name in names(headers)) {
      value <- headers[[name]]
      cmd_args <- c(cmd_args, paste0('-H "', name, ': ', value, '"'))
    }
  }

  known_curl_opts <- c(
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

  # manage options
  # TODO make introspection function for options
  options <- req$options

  # extract names of request's options
  used_opts <- names(options)

  # identify options that are not known / handled
  unknown_opts <- !used_opts %in% known_curl_opts

  # if any options are found that are not handled below, emit a message
  if (any(unknown_opts)) {
    cli::cli_alert_warning(
      "Unable to translate option{?s} {.val {used_opts[unknown_opts]}}"
    )
  }

  for (name in used_opts) {
    value <- options[[name]]
    # convert known options to curl flags other values are ignored
    curl_flag <- switch(
      name,
      # supports req_timeout()
      "timeout" = paste0("--max-time ", value),
      "connecttimeout" = paste0("--connect-timeout ", value),
      # supports req_proxy()
      "proxy" = paste0("--proxy ", value),
      # supports req_user_agent()
      "useragent" = paste0('--user-agent "', value, '"'),
      "referer" = paste0('--referer "', value, '"'),
      # supports defualt behavior or httr2 following redirects
      # rather than returning 302 status
      "followlocation" = if (value) "--location" else NULL,
      # support req_verbose()
      "verbose" = if (value) "--verbose" else NULL,
      # support req_cookie_preserve() and req_cookies_set()
      "cookiejar" = paste0('--cookie-jar "', value, '"'),
      "cookiefile" = paste0('--cookie "', value, '"')
    )
    cmd_args <- c(cmd_args, curl_flag)
  }

  cmd_args <- req_body_as_curl(req, cmd_args)

  # quote the url
  url_quoted <- sprintf('"%s"', url)

  # if we have no arguments we just paste curl and the url together
  res <- if (length(cmd_args) == 0) {
    paste0("curl ", url_quoted)
  } else {
    cmd_lines <- paste0(cmd_args, " \\")

    # indent all args except the first
    cmd_lines[-1] <- paste0("  ", cmd_lines[-1])

    # append the url
    cmd_lines <- c(cmd_lines, paste0("  ", url_quoted))

    # combine with new line separation for all but first argument
    res <- paste0(
      "curl ",
      cmd_lines[1],
      "\n",
      paste0(cmd_lines[-1], collapse = "\n")
    )
  }

  structure(res, class = "httr2_cmd")
}


req_body_as_curl <- function(req, cmd_args) {
  # extract the body and reveal obfuscated values
  body <- req_get_body(req, obfuscated = "reveal")

  if (rlang::is_null(body)) {
    return(cmd_args)
  }

  body_type <- req$body$type %||% "empty"

  # if content_type set here we use it
  content_type <- req$body$content_type

  # if content_type not set we need to infer from body type
  if (rlang::is_null(content_type) || !nzchar(content_type)) {
    content_type <- switch(
      body_type,
      "json" = "application/json",
      "form" = "application/x-www-form-urlencoded"
    )
  }

  # fetch headers for content-type check
  headers <- req_get_headers(req)

  # if the headers aren't empty AND the content-type header is set
  # we use that instead of what is inferred from the request object
  if (
    !rlang::is_empty(headers) && ("content-type" %in% tolower(names(headers)))
  ) {
    content_type <- headers[["content-type"]]
  }

  if (!rlang::is_null(content_type)) {
    cmd_args <- c(
      cmd_args,
      paste0('-H "Content-Type: ', content_type, '"')
    )
  }

  # add body data
  switch(
    body_type,
    "string" = {
      cmd_args <- c(
        cmd_args,
        paste0('-d "', gsub('"', '\\"', body), '"')
      )
    },
    "raw" = {
      # TODO: should the raw bytes be written to a temp file
      # and be hanlded similarly to file?
      cmd_args <- c(cmd_args, '--data-binary "@-"')
    },
    "file" = {
      cmd_args <- c(cmd_args, paste0('--data-binary "@', body, '"'))
    },
    "json" = {
      json_data <- jsonlite::toJSON(body, auto_unbox = TRUE)
      cmd_args <- c(cmd_args, paste0('-d \'', json_data, '\''))
    },
    "form" = {
      form_string <- paste(
        names(body),
        body,
        sep = "=",
        collapse = "&"
      )
      cmd_args <- c(cmd_args, paste0('-d "', form_string, '"'))
    },
    "multipart" = {
      for (name in names(body)) {
        value <- body[[name]]
        cmd_args <- c(cmd_args, paste0('-F "', name, '=', value, '"'))
      }
    }
  )
  cmd_args
}
