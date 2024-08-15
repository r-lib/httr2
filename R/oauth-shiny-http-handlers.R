#' Handle OAuth for Logged-in App Users
#'
#' This function processes OAuth requests for logged-in users of the app. It
#' checks for an existing OAuth token, and if none is found and authentication
#' is required, it returns `NULL`. Otherwise, it invokes the provided HTTP
#' handler to continue processing the request.
#'
#' @param req A `shiny` request object.
#' @param client_config A list of client configurations used for OAuth.
#' @param require_auth Logical, whether authentication is required.
#' @param cookie The name of the cookie where the app's token is stored.
#' @param key A secret key used to encrypt and decrypt tokens.
#' @param httpHandler A function to handle HTTP requests after authentication.
#'
#' @return An HTTP response object or `NULL` if authentication fails.
handle_oauth_app_logged_in <- function(req, client_config, require_auth, cookie, key, httpHandler) {
  token <- oauth_shiny_get_app_token_from_request(req, cookie, key)
  if (is.null(token) && require_auth) {
    return(NULL)
  }

  httpHandler(req)
}

#' Handle OAuth Login for App
#'
#' This function handles the OAuth login process for the app. It checks if the
#' request path is the root ("/"), and if so, either redirects to the primary
#' authentication provider or displays a custom login UI. The custom UI can
#' include a message and login options.
#'
#' @param req A `shiny` request object.
#' @param client_config A list of client configurations used for OAuth.
#' @param login_ui A UI function or object that provides a custom login page.
#'
#' @return An HTTP response object or `NULL` if the request path is not the
#'   root.
handle_oauth_app_login <- function(req, client_config, login_ui) {
  if (!isTRUE(req$PATH_INFO == "/")) {
    return(NULL)
  }

  # If no welcome ui is specified, redirect to primary auth provider directly
  if (is.null(login_ui)) {
    for (client in client_config) {
      if (client$auth_provider_primary) {
        resp <- shiny::httpResponse(
          status = 307L,
          headers = rlang::list2(
            Location = client$login_path,
            "Cache-Control" = "no-store"
          )
        )
        return(resp)
      }
    }
  }
  # Otherwise render login ui
  ui <- login_ui
  if (inherits(ui, "httpResponse")) {
    ui
  } else {
    html <- render_static_html_document(ui)
    shiny::httpResponse(
      status = 403L,
      content = html,
      headers = rlang::list2(
        "Cache-Control" = "no-store"
      )
    )
  }
}

#' Handle OAuth Logout for App
#'
#' This function handles the logout process for the app. It deletes the relevant
#' cookies from the user's browser and returns an HTTP response that either
#' displays a logout UI or redirects the user directly.
#'
#' @param req A `shiny` request object.
#' @param client_config A list of client configurations used for OAuth.
#' @param logout_path The path that triggers the app's logout process.
#' @param cookie The name of the cookie where the app's token is stored.
#' @param logout_ui A UI function or object that provides a custom logout page.
#'
#' @return An HTTP response object or `NULL` if the request path does not match
#'   the logout path.
handle_oauth_app_logout <- function(req, client_config, logout_path, cookie, logout_ui) {
  if (sub("^/", "", req$PATH_INFO) != logout_path) {
    return(NULL)
  }
  cookies_app <- names(parse_cookies(req))
  cookies_clients <- map_chr(client_config, function(x) x[["client_cookie_name"]])
  cookies_regex_match <- paste(c(cookie, cookies_clients), collapse = "|")
  cookies_match <- cookies_app[grepl(cookies_regex_match, cookies_app)]

  cookies_del <- unlist(lapply(cookies_match, delete_cookie_header, cookie_options()))

  html <- render_static_html_document(logout_ui)

  shiny::httpResponse(
    status = 307L,
    content = html,
    headers = rlang::list2(
      !!!cookies_del
    )
  )
}
#' Handle OAuth Client Login
#'
#' This function initiates the OAuth login process for clients configured with
#' the app. It loops through the client configurations and redirects the user to
#' the appropriate OAuth authorization URL.
#'
#' @param req A `shiny` request object.
#' @param client_config A list of client configurations used for OAuth.
#'
#' @return An HTTP response object or `NULL` if no client is matched.
handle_oauth_client_login <- function(req, client_config) {
  for (client in client_config) {
    resp <- handle_oauth_client_login_redirect(req, client)
    if (!is.null(resp)) {
      return(resp)
    }
  }
}

#' Handle OAuth Client Login Redirect
#'
#' This function handles redirection to the OAuth authorization URL for a
#' specific client. It manages PKCE (Proof Key for Code Exchange) if enabled,
#' and sets up necessary cookies before redirecting the user.
#'
#' @param req A `shiny` request object.
#' @param client A single client configuration object.
#'
#' @return An HTTP response object or `NULL` if the request path does not match
#'   the client's login path.
handle_oauth_client_login_redirect <- function(req, client) {
  if (sub("^/", "", req$PATH_INFO) != client$login_path) {
    return(NULL)
  }

  state <- paste0(client$id, base64_url_rand(32))
  auth_params <- client$auth_params

  # Handle PKCE
  if (client$pkce) {
    pkce_code <- oauth_flow_auth_code_pkce()
    auth_params$code_challenge <- pkce_code$challenge
    auth_params$code_challenge_method <- pkce_code$method
    set_cookie_header_pkce <- set_cookie_header("oauth_pkce_verifier", pkce_code$verifier, cookie_options())
  } else {
    set_cookie_header_pkce <- NULL
  }

  # If openid, resolve urls if necessary and set issuer to avoid mixup attacks
  if (!is.null(client$openid_issuer_url)) {
    client <- oauth_shiny_client_openid_resolve_urls(client)
    auth_params$issuer_url <- utils::URLencode(client$openid_issuer_url)
  }

  auth_code_url <- oauth_flow_auth_code_url(
    client = client,
    auth_url = client$auth_url,
    redirect_uri = client$redirect_uri,
    scope = client$scope,
    state = state,
    auth_params = auth_params
  )

  shiny::httpResponse(
    status = 307L,
    headers = rlang::list2(
      Location = auth_code_url,
      "Cache-Control" = "no-store",
      !!!set_cookie_header("oauth_state", state, cookie_options()),
      !!!set_cookie_header_pkce
    )
  )
}

#' Handle OAuth Client Callback
#'
#' This function processes the OAuth callback after the user has authorized the
#' app. It exchanges the authorization code for an access token, handles PKCE
#' verification, and sets cookies for both the app and the client access token.
#'
#' @param req A `shiny` request object.
#' @param client_config A list of client configurations used for OAuth.
#' @param require_auth Logical, whether authentication is required.
#' @param cookie The name of the cookie where the app's token is stored.
#' @param key A secret key used to encrypt and decrypt tokens.
#' @param token_validity The duration for which the token should be cached.
#'
#' @return An HTTP response object or `NULL` if the callback parameters are
#'   invalid.
handle_oauth_client_callback <- function(req, client_config, require_auth, cookie, key, token_validity) {
  query <- shiny::parseQueryString(req[["QUERY_STRING"]])
  if (is.null(query$code) || is.null(query$state)) {
    return(NULL)
  }

  # Verify retrieved state vs cookie state
  state <- parse_cookies(req)[["oauth_state"]]
  if (is.null(state)) {
    cli::cli_alert_warning("No cookie with state was found.")
    cli::cli_li("Does the callback url (redirect) match the app url?")
  }
  code <- oauth_flow_auth_code_parse(query, state)
  pkce <- parse_cookies(req)[["oauth_pkce_verifier"]]

  # TODO: Refactor into function and validate exactly one match
  client <- oauth_shiny_callback_resolve_client(client_config, query)

  # If openid, retrieve config for signature verification and resolving urls
  if (!is.null(client$openid_issuer_url)) {
    openid_config <- oauth_shiny_client_openid_config(client)
    client <- oauth_shiny_client_openid_resolve_urls(client, openid_config)
  }

  # Add PKCE verifier if applicable
  if (!is.null(pkce)) {
    client$token_params$code_verifier <- pkce
    delete_cookie_header_pkce <- delete_cookie_header("oauth_pkce_verifier", cookie_options())
  } else {
    delete_cookie_header_pkce <- NULL
  }

  # Retrieve token
  token <- oauth_client_get_token(
    oauth_client(
      id = client$id,
      secret = client$secret,
      token_url = client$token_url
    ),
    grant_type = "authorization_code",
    code = code,
    redirect_uri = client$redirect_uri,
    !!!client$token_params
  )

  # If openid, verify signature and extract claims
  if (!is.null(client$openid_issuer_url)) {
    claims <- oauth_shiny_client_openid_verify_claims(client, openid_config, token)
  }

  # If token should be post-processed (e.g. exchanged or similar), do it here
  if (!is.null(client$postprocess_token)) {
    token <- client$postprocess_token(token)
  }

  # Set access token as cookie so it can be retrieved after redirection to app
  set_access_token_cookie <- oauth_shiny_set_access_token(
    client = client,
    token = token,
    key = key
  )

  # Set app token as cookie if the callback client is an auth provider for app
  if (client$auth_provider && require_auth) {
    # If the client is an OpenID provider, extract standard claims
    if (!is.null(client$openid_issuer_url)) {
      claims <- claims[client$openid_claims]
    } else {
      claims <- list()
    }

    # If the client has a custom claims function, use that
    if (!is.null(client$auth_set_custom_claim)) {
      claims <- client$auth_set_custom_claim(client, token)
    }

    # Generate a unique identifier for the user which will be verified on login
    claims$identifier <- secret_make_key()
    claims$provider <- client$name

    set_app_token_cookie <- oauth_shiny_set_app_token(
      claims = claims,
      cookie = cookie,
      key = key,
      token_validity = token_validity
    )
  } else {
    set_app_token_cookie <- NULL
  }

  shiny::httpResponse(
    status = 307L,
    content_type = NULL,
    content = "",
    headers = rlang::list2(
      Location = oauth_shiny_infer_app_url(req),
      "Cache-Control" = "no-store",
      !!!delete_cookie_header("oauth_state", cookie_options()),
      !!!delete_cookie_header_pkce,
      !!!set_app_token_cookie,
      !!!set_access_token_cookie
    )
  )
}

#' Handle OAuth Client Logout
#'
#' This function manages the logout process for OAuth clients. It deletes the
#' relevant cookies and redirects the user back to the app.
#'
#' @param req A `shiny` request object.
#' @param client_config A list of client configurations used for OAuth.
#'
#' @return An HTTP response object or `NULL` if no client is matched.
handle_oauth_client_logout <- function(req, client_config) {
  for (client in client_config) {
    resp <- handle_oauth_client_logout_delete_cookies(req, client)
    if (!is.null(resp)) {
      return(resp)
    }
  }
}

#' Handle OAuth Client Logout - Delete Cookies
#'
#' This function deletes the cookies associated with a specific OAuth client
#' during the logout process. It then redirects the user back to the app.
#'
#' @param req A `shiny` request object.
#' @param client A single client configuration object.
#'
#' @return An HTTP response object or `NULL` if the request path does not match
#'   the client's logout path.
handle_oauth_client_logout_delete_cookies <- function(req, client) {
  if (sub("^/", "", req$PATH_INFO) != client$logout_path) {
    return(NULL)
  }

  cookies_app <- names(parse_cookies(req))
  cookies_match <- cookies_app[grepl(client$client_cookie_name, cookies_app)]
  cookies_del <- unlist(lapply(cookies_match, delete_cookie_header, cookie_options()))

  shiny::httpResponse(
    status = 307L,
    headers = rlang::list2(
      Location = oauth_shiny_infer_app_url(req),
      "Cache-Control" = "no-store",
      !!!cookies_del
    )
  )
}

#' Resolve OAuth Client in Callback
#'
#' This function resolves which OAuth client configuration should be used during
#' the callback phase based on the query parameters returned by the OAuth
#' server. It ensures that the client matches either the state parameter or the
#' OpenID issuer URL.
#'
#' @param client_config A list of client configurations used for OAuth.
#' @param query A list of query parameters from the OAuth callback request.
#'
#' @return The matching client configuration object.
oauth_shiny_callback_resolve_client <- function(client_config, query) {
  for (client in client_config) {
    # To-do: Maybe catch this earlier? Should we even allow a missing client id
    if (is.null(client$id) || client$id == "") {
      next
    }
    if (!is.null(client$openid_issuer_url) && !is.null(query$iss)) {
      if (sub("/$", "", client$openid_issuer_url) == sub("/$", "", query$iss)) {
        # If matches openid issuer
        return(client)
      }
    } else if (grepl(client$id, query$state) && is.null(query$iss)) {
      # If matches state
      return(client)
    }
  }
  cli::cli_abort("Callback from server matches neither issuer or state")
}
