#' Integrate OAuth into a Shiny Application
#'
#' @description This function integrates OAuth-based authentication into Shiny
#'   applications, managing the full OAuth authorization code flow including
#'   token acquisition, storage, and session management. It supports two main
#'   scenarios:
#'
#'   1. **Enforcing User Login**: Users must authenticate through an OAuth
#'   provider before accessing the Shiny app. The login interface can be
#'   automatically generated based on the `client_config` or provided via the
#'   `login_ui` parameter. Alternatively, you can bypass the login UI and
#'   redirect users directly to the OAuth client by setting `login_ui` to `NULL`
#'   and configuring a primary authentication provider in the `client_config`.
#'   This setup is useful in enterprise environments where seamless integration
#'   with single sign-on (SSO) solutions is desired.
#'
#'   2. **Retrieving Tokens on Behalf of Users**: This functionality allows for
#'   obtaining OAuth tokens from users, which can be used for accessing external
#'   APIs. This can be applied whether or not user login is enforced. When
#'   `require_auth = TRUE`, users must log in, and the tokens can be used in the
#'   context of their authenticated session. When `require_auth = FALSE`, tokens
#'   are retrieved from users in a public app setting where login is optional or
#'   not enforced. In both scenarios, tokens are stored securely in encrypted
#'   cookies and can be retrieved using `oauth_shiny_get_access_token()`.
#'
#'   The function manages OAuth by setting two types of cookies:
#'   - **App Cookie**: Contains a JSON Web Token (JWT) that holds user claims
#'   such as `name`, `email`, `sub`, and `aud`. This cookie is used to maintain
#'   the user's session in the Shiny app. It can be retrieved in a shiny app
#'   using `oauth_shiny_get_app_token()`
#'   - **Access Token Cookie**: If the `access_token_validity` for a client is
#'   greater than 0, an additional cookie is created to store the OAuth access
#'   token. This cookie is encrypted and can be retrieved using
#'   `oauth_shiny_get_access_token()`.
#'
#' @param app A Shiny app object, typically created using [shiny::shinyApp()].
#'   For improved readability, consider using the pipe operator, e.g.,
#'   `shinyApp() |> oauth_shiny_app(...)`.
#' @param client_config An `oauth_shiny_config` object that specifies the OAuth
#'   clients to be used. This object should include configurations for one or
#'   more OAuth providers, created with `oauth_shiny_client_*()` functions.
#' @param require_auth Logical; determines whether user authentication is
#'   mandatory before accessing the app. Set to `TRUE` to enforce login, which
#'   will redirect unauthenticated users to the OAuth login UI. Set to `FALSE`
#'   for a public app where login is optional but token retrieval is still
#'   supported. Defaults to `TRUE`.
#' @param key The encryption key used to secure cookies containing
#'   authentication information. This key should be a long, randomly generated
#'   string. By default, it is retrieved from the environment variable
#'   `HTTR2_OAUTH_PASSPHRASE`. You can generate a suitable key using
#'   `httr2::secret_make_key()` or a similar method.
#' @param dark_mode Logical; specifies whether the login and logout user
#'   interfaces should use a dark mode theme. If `TRUE`, the interfaces will
#'   adopt a dark color scheme. Defaults to `FALSE`.
#' @param login_ui The user interface displayed to users for login when
#'   `require_auth = TRUE`. By default, this is automatically generated based on
#'   the OAuth clients specified in `client_config`. You can provide a custom UI
#'   if desired.
#' @param logout_ui The user interface shown to users for logout. By default,
#'   this UI is automatically generated based on the OAuth clients in
#'   `client_config`. You can provide a custom UI to override the default
#'   behavior.
#' @param logout_path The URL path used to handle user logout requests. Users
#'   will be redirected to this path to log out of the application. Defaults to
#'   `'logout'`. If you wish to customize the logout path, specify it here.
#' @param logout_on_token_expiry Logical; determines if users should be
#'   automatically logged out when the app token expires. If `TRUE`, the user
#'   session will end when the token expires. If `FALSE`, the session remains
#'   active until the user manually logs out or refreshes the browser. Defaults
#'   to `FALSE`.
#' @param cookie_name The name of the cookie used to store authentication
#'   information. This cookie holds the app token containing user claims.
#'   Defaults to `'oauth_app_token'`. You can specify a different name if
#'   needed.
#' @param token_validity Numeric; the duration in seconds for which the user's
#'   session remains valid. This controls how long the JWT or access token is
#'   valid before it expires. Defaults to `3600` seconds (1 hour).
#'
#' @export
oauth_shiny_app <- function(
    app,
    client_config,
    require_auth = TRUE,
    key = oauth_shiny_app_passphrase(),
    dark_mode = FALSE,
    login_ui = oauth_shiny_ui_login(client_config, dark_mode),
    logout_ui = oauth_shiny_ui_logout(client_config, dark_mode),
    logout_path = "logout",
    logout_on_token_expiry = FALSE,
    cookie_name = "oauth_app_token",
    token_validity = 3600) {
  # This function takes the app object and transforms/decorates it to create a
  # new app object. The new app object will wrap the original ui/server with
  # authentication logic, so that the original ui/server is not invoked unless
  # and until the user has a valid Google token.

  check_installed("jose")
  check_installed("sodium")

  # Force and normalize arguments
  force(app)
  force(client_config)
  force(login_ui)
  force(logout_ui)

  if (is.null(key) || is.na(key) || key == "") {
    cli::cli_abort("Must supply either {.arg key} or set environment variable {.arg HTTR2_OAUTH_PASSPHRASE}")
  } else if (nchar(key) < 16) {
    cli::cli_alert_warning("You are using a key of less than 16 characters")
  }

  # Override the HTTP handler, which is the "front door" through which a browser
  # comes to the Shiny app.
  httpHandler <- app$httpHandler
  app$httpHandler <- function(req) {
    # Each handle_* function will decide if it can handle the request, based on
    # the URL path, request method, presence/absence/validity of cookies, etc.
    # The return value will be NULL if the `handle` function couldn't handle the
    # request, and either HTML tag objects or a shiny::httpResponse if it
    # decided to handle it.
    resp <-
      # The logout_path revokes all app and client tokens and deletes cookies
      handle_oauth_app_logout(req, client_config, logout_path, cookie_name, logout_ui) %||%
      # The client logout_path revokes a single client token and deletes cookies
      handle_oauth_client_logout(req, client_config) %||%
      # The client login_path handles redirection to the specific client
      handle_oauth_client_login(req, client_config) %||%
      # Handles callback from oauth client (after login)
      handle_oauth_client_callback(req, client_config, require_auth, cookie_name, key, token_validity) %||%
      # Handles requests that have good cookies or does not require auth
      handle_oauth_app_logged_in(req, client_config, require_auth, cookie_name, key, httpHandler) %||%
      # If we get here, the user isn't logged in
      handle_oauth_app_login(req, client_config, login_ui)

    resp
  }

  # Only invoke the provided server logic if the user is logged in; and make the
  # token automatically available within the server logic
  serverFuncSource <- app$serverFuncSource
  app$serverFuncSource <- function() {
    wrappedServer <- serverFuncSource()
    function(input, output, session) {
      token <- oauth_shiny_get_app_token(cookie_name, key)
      if (is.null(token) && require_auth) {
        cli::cli_abort("No valid OAuth token was found on the websocket connection")
        return(NULL)
      } else {
        if (require_auth && logout_on_token_expiry) {
          # Since Shiny can only request cookies at the start up of the app, the
          # cookie can be expired when the user is active beyond the cookie
          # lifetime. In this case, we can force a refresh of the app which will
          # ensure that the cookie is no longer available. This can appear
          # unfriendly for the user who will be immediately redirected back to
          # the login screen but until we have a clear strategy for how token
          # refresh should work, this seems like a good temporary solution.
          expiry_time <- ceiling(token[["exp"]] + 1 - unix_time()) * 1000
          token_expired <- shiny::reactiveTimer(expiry_time)
          shiny::observeEvent(token_expired(), session$reload(), ignoreInit = TRUE)
        }
        wrappedServer(input, output, session)
      }
    }
  }

  onStart <- app$onStart
  app$onStart <- function() {
    # Call original onStart, if any
    if (is.function(onStart)) {
      onStart()
    }
  }

  app
}

#' Extract server URL from the request
#'
#' @description Inferring the correct app url on the server requires some work.
#' This function attempts to guess the correct server url, but may fail outside
#' of tested hosts (´127.0.0.1` and `shinyapps.io`). To be sure, set the
#' environment variable `HTTR2_OAUTH_APP_URL` explicitly. Logic inspired by
#' [https://github.com/r4ds/shinyslack](r4ds/shinyslack).
#' @param req A request object.
#'
#' @return The app url.
#' @keywords internal

oauth_shiny_infer_app_url <- function(req) {
  if (!is.na(oauth_shiny_app_url())) {
    return(oauth_shiny_app_url())
  }

  if (any(
    c("x-redx-frontend-name", "http_x_redx_frontend_name")
    %in% tolower(names(req))
  )) {
    url <- req$HTTP_X_REDX_FRONTEND_NAME %||%
      req$http_x_redx_frontend_name %||%
      req$`X-REDX-FRONTEND-NAME` %||%
      req$`x-redx-frontend-name`

    scheme <- req$HTTP_X_FORWARDED_PROTO %||%
      req$http_x_forwarded_proto %||%
      req$`X-FORWARDED-PROTO` %||%
      req$`x-forwarded-proto`
  } else {
    url <- req$SERVER_NAME %||% req$server_name

    if (is.null(url)) {
      cli::cli_abort(
        message = c(x = "Could not determine url.")
      )
    }

    port <- req$SERVER_PORT %||% req$server_port

    if (!is.null(port)) {
      url <- paste(url, port, sep = ":")
    }

    scheme <- req$rook.url_scheme
  }

  url <- paste0(scheme, "://", url)
  url <- sub("\\?.*", "", url)
  url
}

#' Override app url for OAuth
#'
#' It can be difficult to correctly infer the correct app url depending on
#' which environment the app is running in (localhost, shinyapps, cloud, etc).
#' httr2 makes an attempt to guess the correct app url, but the environment
#' variable `HTTR2_OAUTH_APP_URL` could be used to override a wrong guess.
#'
#' @export
oauth_shiny_app_url <- function() {
  Sys.getenv("HTTR2_OAUTH_APP_URL", NA_character_)
}

#' Default passphrase
#'
#' @export
oauth_shiny_app_passphrase <- function() {
  Sys.getenv("HTTR2_OAUTH_PASSPHRASE", NA_character_)
}
