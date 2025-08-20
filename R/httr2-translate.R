#' Translate httr2 request to curl command
#'
#' Convert an httr2 request object to equivalent curl command line syntax.
#' This is useful for debugging, sharing requests, or converting to other tools.
#'
#' @param .req An httr2 request object created with [request()].
#' @return A character string containing the curl command.
#' @export
#' @examples
#' \dontrun{
#' # Basic GET request
#' request("https://httpbin.org/get") |>
#'   httr2_translate()
#'
#' # POST with JSON body
#' request("https://httpbin.org/post") |>
#'   req_body_json(list(name = "value")) |>
#'   httr2_translate()
#'
#' # POST with form data
#' request("https://httpbin.org/post") |>
#'   req_body_form(name = "value") |>
#'   httr2_translate()
#' }
httr2_translate <- function(.req) {
  # validate the request
  check_request(.req)

  # Extract URL
  url <- .req$url

  # use the request's method if it is set, otherwise infer
  method <- .req$method %||%
    {
      if (!is.null(.req$body$data)) {
        "POST"
      } else {
        "GET"
      }
    }

  # we will append to cmd_parts to build up the request
  cmd_parts <- c("curl")

  # if the method isn't GET, it needs to be specified with `-X`
  if (method != "GET") {
    cmd_parts <- c(cmd_parts, paste0("-X ", method))
  }

  # if headers are present, add them using -H flag
  if (!is.null(.req$headers) && length(.req$headers) > 0) {
    headers <- .req$headers
    for (name in names(headers)) {
      value <- headers[[name]]

      # handle weakrefs
      if (rlang::is_weakref(value)) {
        value <- rlang::wref_value(value)
      }

      # unobfuscate obfuscated
      if (is_obfuscated(value)) {
        value <- unobfuscate(value, handle = "reveal")
      }

      cmd_parts <- c(cmd_parts, paste0('-H "', name, ': ', value, '"'))
    }
  }

  # manage options
  if (!is.null(.req$options) && length(.req$options) > 0) {
    options <- .req$options
    for (name in names(options)) {
      value <- options[[name]]
      # convert options to curl flags
      curl_flag <- switch(
        name,
        "timeout" = paste0("--max-time ", value),
        "connecttimeout" = paste0("--connect-timeout ", value),
        "proxy" = paste0("--proxy ", value),
        "useragent" = paste0('--user-agent "', value, '"'),
        "referer" = paste0('--referer "', value, '"'),
        "followlocation" = if (value) "--location" else NULL,
        "ssl_verifypeer" = if (!value) "--insecure" else NULL,
        "verbose" = if (value) "--verbose" else NULL,
        "cookiejar" = paste0('--cookie-jar "', value, '"'),
        "cookiefile" = paste0('--cookie "', value, '"'),
        # for unknown options try guess the flag if it was the intention
        paste0("--", gsub("_", "-", name), " ", value)
      )
      if (!is.null(curl_flag)) {
        cmd_parts <- c(cmd_parts, curl_flag)
      }
    }
  }

  if (!is.null(.req$body)) {
    body_type <- .req$body$type %||% "empty"
    # if content_type set here we use it
    content_type <- .req$body$content_type

    # if content_type not set we need to infer from body type
    if (is.null(content_type) || !nzchar(content_type)) {
      if (body_type == "json") {
        content_type <- "application/json"
      } else if (body_type == "form") {
        content_type <- "application/x-www-form-urlencoded"
      }
    }

    # add content-type header if we have one and it's not already set
    if (!is.null(content_type)) {
      if (
        is.null(.req$headers) ||
          !("content-type" %in% tolower(names(.req$headers)))
      ) {
        cmd_parts <- c(
          cmd_parts,
          paste0('-H "Content-Type: ', content_type, '"')
        )
      }
    }

    # add body data
    switch(
      body_type,
      "string" = {
        data <- .req$body$data
        cmd_parts <- c(cmd_parts, paste0('-d "', gsub('"', '\\"', data), '"'))
      },
      "raw" = {
        # Raw bytes - use --data-binary
        cmd_parts <- c(cmd_parts, '--data-binary "@-"')
      },
      "file" = {
        path <- .req$body$data
        cmd_parts <- c(cmd_parts, paste0('--data-binary "@', path, '"'))
      },
      "json" = {
        data <- unobfuscate(.req$body$data, handle = "reveal")
        json_data <- jsonlite::toJSON(data, auto_unbox = TRUE)
        cmd_parts <- c(cmd_parts, paste0('-d \'', json_data, '\''))
      },
      "form" = {
        form_data <- unobfuscate(.req$body$data, handle = "reveal")
        form_string <- paste(
          names(form_data),
          form_data,
          sep = "=",
          collapse = "&"
        )
        cmd_parts <- c(cmd_parts, paste0('-d "', form_string, '"'))
      },
      "multipart" = {
        form_data <- unobfuscate(.req$body$data, handle = "reveal")
        for (name in names(form_data)) {
          value <- form_data[[name]]
          cmd_parts <- c(cmd_parts, paste0('-F "', name, '=', value, '"'))
        }
      }
    )
  }

  cmd_parts <- c(cmd_parts, paste0('"', url, '"'))

  # join all parts with proper formatting
  if (length(cmd_parts) <= 2) {
    paste(cmd_parts, collapse = " ")
  } else {
    # need to ensure that "curl" isn't on its own line
    # for compatibility with curl_translate()
    first_part <- paste(cmd_parts[1:2], collapse = " ")
    remaining_parts <- cmd_parts[-(1:2)]

    if (length(remaining_parts) == 0) {
      first_part
    } else {
      formatted_parts <- paste0("  ", remaining_parts, " \\")
      # Remove the trailing backslash from the last part
      formatted_parts[length(formatted_parts)] <- gsub(
        " \\\\$",
        "",
        formatted_parts[length(formatted_parts)]
      )

      paste(c(paste0(first_part, " \\"), formatted_parts), collapse = "\n")
    }
  }
}
