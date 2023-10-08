oauth_flow_fetch <- function(req, source, error_call = caller_env()) {
  req <- req_error(req, is_error = ~ FALSE)
  resp <- req_perform(req, error_call = current_call())

  oauth_flow_parse(resp, source, error_call = error_call)
}

oauth_flow_parse <- function(resp, source, error_call = caller_env()) {
  withCallingHandlers(
    body <- oauth_flow_body(resp),
    error = function(err) {
      cli::cli_abort(
        "Failed to parse response from {.arg {source}} OAuth url.",
        parent = err,
        call = error_call
      )
    }
  )

  if (has_name(body, "expires_in")) {
    body$expires_in <- as.numeric(body$expires_in)
  }

  # This is rather more flexible than what the spec requires, and should
  # hopefully be general enough to handle most token endpoints. However,
  # it would still be nice to figure out how to make user extensible,
  # especially since you might be able to give better errors.
  if (resp_status(resp) == 200) {
    if (has_name(body, "access_token")) {
      return(body)
    }
    if (has_name(body, "device_code")) {
      return(body)
    }
  } else {
    if (has_name(body, "error")) {
      oauth_flow_abort(
        body$error,
        body$error_description,
        body$error_uri,
        error_call = error_call
      )
    }
  }

  cli::cli_abort(
    c(
      "Failed to parse response from {.arg {source}} url.",
      "*" = "Did not contain {.code access_token}, {.code device_code}, or {.code error} field."
    ),
    call = error_call
  )
}

oauth_flow_body <- function(resp) {
  resp_body_json(resp, check_type = NA)
}

# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1
# https://datatracker.ietf.org/doc/html/rfc6749#section-4.2.2.1
# https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
#
# TODO: automatically fill in description from text in RFC?
oauth_flow_abort <- function(error,
                             description = NULL,
                             uri = NULL,
                             error_call = caller_env()) {
  cli::cli_abort(
    c(
      "OAuth failure [{error}]",
      "*" = description,
      i = if (!is.null(uri)) "Learn more at {.url {uri}}."
    ),
    code = error,
    class = c(glue("httr2_oauth_{error}"), "httr2_oauth"),
    call = error_call
  )
}
