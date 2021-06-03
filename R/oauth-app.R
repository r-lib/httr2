oauth_app <- function(client, endpoints, auth = c("body", "header")) {
  if (!inherits(client, "httr2_oauth_client")) {
    abort("`client` must be an OAuth client created with `oauth_client()`")
  }

  if (!is.character(endpoints) || is_named(endpoints)) {
    abort("`endpoints` must be a named character vector")
  }
  if (!has_name(endpoints, "token")) {
    abort("`endpoints` must contain a token endpoint")
  }

  auth <- arg_match(auth)
  if (auth == "header" && is.null(client$secret)) {
    abort("`auth = 'header' requires a client with a secret")
  }

  structure(
    list(client = client, endpoints = endpoints, auth = auth),
    class = "httr2_oauth_app"
  )
}

oauth_client <- function(client_id, client_secret = NULL) {
  # TODO: provide some lightweight way of encrypting the secret so that it
  # never appears in plain text

  structure(
    list(
      id = client_id,
      secret = client_secret
    ),
    class = "httr2_oauth_client"
  )
}

#' @export
print.httr2_oauth_client <- function(x, ...) {
  type <- if (is.null(x$secret)) "public" else "confidental"
  cli::cli_text("{.cls {class(x)}} ID: {x$id} ({type})")
}

# Authenticate a request using an OAuth client using the auth method defined by
# the app. This is used to authenticate the client at various places during the
# oauth flow, NOT for authentication on behalf of the user.
#
# TODO: implement JWT auth
# TODO: make user extensible
req_auth_oauth_client <- function(req, app) {
  if (app$auth == "body") {
    params <- compact(list(
      client_id = app$client$id,
      client_secret = app$client$secret # might be NULL
    ))
    req_body_form_append(req, params)
  } else {
    req_auth_basic(req, app$client$id, app$client$secret)
  }
}

# Helpers -----------------------------------------------------------------

check_app <- function(app) {
  if (!inherits(app, "httr_oauth_app")) {
    abort("`app` must be an OAuth app created with `oauth_app()`")
  }
}

oauth_flow_check_app <- function(app, flow,
                                 is_confidential = FALSE,
                                 endpoints = character(),
                                 interactive = TRUE) {
  check_app(app)

  if (is_confidential && !is.null(app$client$secret)) {
    abort(c(
      glue("Can't use this `app` with OAuth 2.0 {flow} flow"),
      "`app` must have a confidential client (i.e. `client_secret` is required)"
    ))
  }

  missing <- setdiff(endpoints, names(app$endpoints))
  if (length(missing)) {
    abort(c(
      glue("Can't use this `app` with OAuth 2.0 {flow} flow"),
      glue("`app` lacks endpoints '{missing}'")
    ))
  }

  if (interactive && !is_interactive()) {
    abort(glue("OAuth 2.0 {flow} flow requires an interactive session"))
  }
}

app_endpoint <- function(app, endpoint) {
  if (!has_name(app$endpoints, endpoint)) {
    abort("app missing endpoint '{endpoint}'")
  }
  app$endpoints[[endpoint]]
}
