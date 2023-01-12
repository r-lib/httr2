oauth_flow_fetch <- function(req) {
  req <- req_error(req, is_error = ~ FALSE)
  resp <- req_perform(req, error_call = current_call())

  # This is rather more flexible than what the spec requires, and should
  # hopefully be general enough to handle most token endpoints. However,
  # it would still be nice to figure out how to make user extensible,
  # especially since you might be able to give better errors.
  if (resp_content_type(resp) == "application/json") {
    body <- resp_body_json(resp)

    if (has_name(body, "expires_in")) {
      body$expires_in <- as.numeric(body$expires_in)
    }
  } else {
    body <- NULL
  }

  if ((has_name(body, "access_token") || has_name(body, "device_code")) && resp_status(resp) == 200) {
    body
  } else if (has_name(body, "error")) {
    oauth_flow_abort(body$error, body$error_description, body$error_uri)
  } else {
    resp_check_status(resp)
    abort("Failed to process response from 'token' endpoint")
  }

}

# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1
# https://datatracker.ietf.org/doc/html/rfc6749#section-4.2.2.1
# https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
#
# TODO: automatically fill in description from text in RFC?
oauth_flow_abort <- function(error, description = NULL, uri = NULL) {
  message <- c(
    glue("OAuth failure [{error}]"),
    description,
    i = if (!is.null(uri)) glue("Learn more at <{uri}>")
  )
  abort(
    message,
    code = error,
    class = c(glue("httr2_oauth_{error}"), "httr2_oauth")
  )
}
