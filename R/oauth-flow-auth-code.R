# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1
oauth_flow_auth_code <- function(app,
                                 scope = NULL,
                                 pkce = TRUE,
                                 auth_params = list(),
                                 token_params = list(),
                                 host = "127.0.0.1",
                                 port = 1410
) {
  oauth_flow_check_app(app,
    flow = "authorization code",
    is_confidential = TRUE,
    endpoints = c("token", "authorization"),
    interactive = TRUE
  )
  check_installed("httpuv2")

  state <- nonce()
  redirect_url <- paste0("http://", host, ":", port)

  # TODO: implement PKCE

  # Redirect user to authorisation url, and listen for result
  user_url <- oauth_flow_auth_code_url(app,
    redirect_url = redirect_url,
    scope = scope,
    state = state,
    !!!auth_params
  )
  utils::browseURL(user_url)
  result <- oauth_flow_auth_code_listen(host, port)
  code <- oauth_flow_auth_code_parse(result, state)

  # Get access/refresh token from authorisation code
  # https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
  oauth_flow_access_token(app,
    grant_type = "authorization_code",
    code = code,
    redirect_uri = redirect_url,
    !!!token_params
  )
}

# Authorisation request: make a url that the user navigates to
# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.1
oauth_flow_auth_code_url <- function(app,
                                   response_type = "code",
                                   redirect_uri = NULL,
                                   scope = NULL,
                                   state = NULL,
                                   ...) {
  url <- app_endpoint(app, "authorization")
  httr::modify_url(url, query = list2(
    response_type = response_type,
    client_id = app$client$id,
    redirect_uri = redirect_uri,
    scope = scope,
    state = state,
    ...
  ))
}

# Start local server to listen to redirect
oauth_flow_auth_code_listen <- function(host = "127.0.0.1", port = 1410) {
  complete <- FALSE
  info <- NULL
  listen <- function(env) {
    browser()

    if (!identical(env$PATH_INFO, "/")) {
      return(list(
        status = 404L,
        headers = list("Content-Type" = "text/plain"),
        body = "Not found"
      ))
    }

    # TODO: parse out fragment
    query <- env$QUERY_STRING
    if (!is.character(query) || identical(query, "")) {
      complete <<- TRUE
    } else {
      complete <<- TRUE
      info <<- httr:::parse_query(gsub("^\\?", "", query))
    }

    list(
      status = 200L,
      headers = list("Content-Type" = "text/plain"),
      body = "Authentication complete. Please close this page and return to R."
    )
  }
  server <- httpuv::startServer(host, port, list(call = listen))
  withr::defer(httpuv::stopServer(server))

  # TODO: make this a progress bar
  inform("Waiting for authentication in browser...")
  inform("Press Esc/Ctrl + C to abort")
  while (!complete) {
    httpuv::service()
  }
  httpuv::service() # send data back to client

  if (!is.null(abort)) {
    abort("Authentication failed; invalid url from server.")
  }

  info
}

# Authorisation response: get query params back from redirect
# https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2
oauth_flow_auth_code_parse <- function(query, state) {
  if (has_name(query, "error")) {
    # https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1
    # Never see problems with redirect_uri
    oauth_flow_abort(query$error, query$error_description, query$error_uri)
  }

  if (query$state != state) {
    abort("Authentication failure: state does not match")
  }

  query$code
}
