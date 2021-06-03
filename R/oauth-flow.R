oauth_flow_access_token <- function(app, ...) {
  url <- app_endpoint(app, "token")

  req <- req(url)
  req <- req_body_form(req, list2(...))
  req <- req_auth_oauth_client(req, app)

  req <- req_error(req, is_error = ~ FALSE)
  resp <- req_fetch(req)

  # TODO: figure out how to make this user configurable
  if (resp_status(resp) == 200) {
    body <- resp_body_json(resp)
    exec(new_token, body, .date = resp_date(resp))
  } else if (resp_status(resp) == 400) {
    body <- resp_body_json(resp)
    oauth_flow_abort(body$error, body$error_description, body$error_uri)
  } else {
    abort("Unknown status code from access endpoint")
  }
}

# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1
# https://datatracker.ietf.org/doc/html/rfc6749#section-4.2.2.1
# https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
#
# TODO: automatically fill in description from text in RFC?
oauth_flow_abort <- function(error, description = NULL, uri = NULL) {
  message <- c(
    glue("OAuth failure {error}"),
    description,
    i = if (!is.null(uri)) glue("Learn more at <{uri}>")
  )
  abort(
    message,
    code = error,
    class = c(glue("htt2_oauth_{error}"), "httr2_oauth")
  )
}
