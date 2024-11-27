format_duration <- function(seconds) {
  days <- seconds %/% (24 * 3600)
  seconds <- seconds %% (24 * 3600)
  hours <- seconds %/% 3600
  seconds <- seconds %% 3600
  minutes <- seconds %/% 60
  seconds <- seconds %% 60

  # Create the formatted string
  result <- c()
  if (days > 0) result <- c(result, paste0(days, " day", ifelse(days > 1, "s", "")))
  if (hours > 0) result <- c(result, paste0(hours, " hour", ifelse(hours > 1, "s", "")))
  if (minutes > 0) result <- c(result, paste0(minutes, " min", ifelse(minutes > 1, "s", "")))
  if (seconds > 0 || length(result) == 0) result <- c(result, paste0(seconds, " sec", ifelse(seconds > 1, "s", "")))

  return(paste(result, collapse = ", "))
}

format_additional_token_information <- function(token, redact) {
  if (is.null(token())) {
    return(NULL)
  }

  nms_reserved <- c("access_token", "cookie_expires_at", "expires_at")
  nms <- !(names(token()) %in% nms_reserved)

  info <- subset(token(), nms)

  map2(info, names(info), function(value, name) {
    value <- if (redact & grepl("_token$", name)) redact_text(value) else value
    shiny::div(
      class = "list-group-item bg-light",
      shiny::h6(class = "my-0 overflow-hidden", value),
      shiny::tags$small(class = "text-muted", name)
    )
  })
}

redact_text <- function(value, symbol = "*", keep_characters = 3) {
  paste0(
    substr(value, 1, keep_characters),
    strrep(symbol, nchar(value) - keep_characters)
  )
}

oauth_shiny_app_example_client_mod_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(
    class = "list-group text-start",
    shiny::div(
      class = "list-group-item d-flex align-items-center justify-content-between",
      shiny::div(
        shiny::div(class = "d-inline", shiny::uiOutput(ns("icon"))),
        shiny::div(class = "d-inline mx-2", shiny::textOutput(ns("client_name"), inline = TRUE)),
      ),
      shiny::uiOutput(ns("button"))
    ),
    shiny::uiOutput(ns("token")),
    shiny::uiOutput(ns("token_expires")),
    shiny::uiOutput(ns("cookie_expires")),
    shiny::uiOutput(ns("token_additional"))
  )
}

oauth_shiny_app_example_client_mod_server <- function(id, client, key, redact) {
  shiny::moduleServer(id, function(input, output, session) {
    token <- shiny::reactive({
      client_token <- oauth_shiny_get_access_token(client, key)
      if (!is.null(client_token)) {
        # Cookies are only accessible to shiny on load and remain until refresh
        # if the session is kept alive. Invalidate tokens here
        cookie_expiry <- client_token[["cookie_expires_at"]] - unix_time()
        if (cookie_expiry > 0) {
          shiny::invalidateLater(cookie_expiry * 1000)
          client_token
        } else {
          NULL
        }
      }
    })

    output$icon <- shiny::renderUI({
      class <- if (is.null(token())) "text-secondary" else "text-primary"

      shiny::icon("circle", class = paste("fas", class))
    })

    output$client_name <- shiny::renderText(client$name)

    output$button <- shiny::renderUI({
      text <- "Log in"
      href <- client$login_path
      class <- "btn btn-sm btn-light"

      if (!is.null(token())) {
        text <- "Log out"
        href <- client$logout_path
      }

      shiny::a(shiny::span(text), href = href, class = class)
    })

    output$token <- shiny::renderUI({
      list_group_class <- "bg-light disabled"
      title <- "Not logged in"

      if (!is.null(token())) {
        token_value <- token()[["access_token"]]
        title <- if (redact) redact_text(token_value) else token_value
        list_group_class <- ""
      }

      shiny::div(
        class = paste("list-group-item border-top-0 border-top-0", list_group_class),
        shiny::div(class = "my-0 overflow-hidden", title),
        shiny::tags$small(class = "opacity-75", "Token")
      )
    })

    output$cookie_expires <- shiny::renderUI({
      cookie_expires_value <- "No cookie"
      list_group_class <- "bg-light disabled"

      if (!is.null(token())) {
        cookie_expires <- token()[["cookie_expires_at"]] - unix_time()
        if (cookie_expires > 0) {
          shiny::invalidateLater(1000)
          cookie_expires_value <- format_duration(cookie_expires)
          list_group_class <- ""
        }
      }

      shiny::div(
        class = paste(class = "list-group-item border-top-0 border-bottom-0", list_group_class),
        shiny::div(class = "my-0 overflow-hidden", cookie_expires_value),
        shiny::tags$small(class = "opacity-75", "Cookie expires")
      )
    })


    output$token_expires <- shiny::renderUI({
      token_expires_value <- "Not logged in"
      list_group_class <- "bg-light disabled"

      if (!is.null(token())) {
        token_expires <- token()[["expires_at"]]
        list_group_class <- ""
        if (is.null(token_expires)) {
          shiny::invalidateLater(1000)
          token_expires_value <- "No expiry date"
        } else if (token_expires > unix_time()) {
          shiny::invalidateLater(1000)
          token_expires_value <- format_duration(as.integer(token_expires - unix_time()))
        }
      }

      shiny::div(
        class = paste(class = "list-group-item border-top-0", list_group_class),
        shiny::div(class = "my-0 overflow-hidden", token_expires_value),
        shiny::tags$small(class = "opacity-75", "Token expires")
      )
    })

    output$token_additional <- shiny::renderUI({
      info <- format_additional_token_information(token, redact)

      if (!is.null(info)) {
        bslib::accordion(
          class = "accordion-flush list-group-item m-0 p-0",
          open = FALSE,
          bslib::accordion_panel(
            "Additional token info",
            shiny::div(class = "list-group text-start", info)
          )
        )
      } else {
        # Manually create an accordion with a disabled look
        style <- "padding: var(--bs-accordion-btn-padding-y); font-size: 1rem"
        shiny::div(
          class = "accordion accordion-flush list-group-item m-0 p-0",
          shiny::div(
            class = "accordion-item",
            shiny::div(
              class = "accordion-header bg-light",
              shiny::div(
                style = style,
                shiny::div(
                  "No additional token info",
                  class = "accordion-title text-muted",
                )
              )
            )
          )
        )
      }
    })
  })
}

#' Example Shiny App Using OAuth
#'
#' This function sets up a Shiny application that uses multiple OAuth providers
#' for authentication. The application can be configured to allow users to sign
#' in using various OAuth providers like Google, Microsoft, GitHub, and others.
#'
#' @param client_config A `oauth_shiny_config` object containing a list of OAuth
#'   client configurations (`oauth_shiny_client` objects).
#' @param require_auth Logical; should login be enforced? Defaults to `FALSE`.
#' @param key The encryption key for securing cookies. Defaults to the
#'   environment variable `HTTR2_OAUTH_PASSPHRASE`. It should be a long,
#'   randomly generated string, which can be created using
#'   `httr2::secret_make_key()` or a similar method.
#' @param dark_mode Logical; should the login and logout UI use dark mode?
#'   Defaults to `FALSE`..
#' @param login_ui The login UI to present to users when `enforce_login = TRUE`.
#'   Defaults to an automatically generated UI based on the clients listed in
#'   `client_config`.
#' @param logout_ui The logout UI to present to users. Defaults to an
#'   automatically generated UI based on the providers listed in
#'   `client_config`.
#' @param logout_path The URL path used to log users out of the app. Defaults to
#'   `'logout'`.
#' @param logout_on_token_expiry Logical; should the user be automatically
#'   logged out of the app when the token expires? If `FALSE`, the session
#'   remains active until the user refreshes the browser or manually logs out.
#'   Defaults to `FALSE`.
#' @param cookie_name The name of the cookie used for authentication. Defaults
#'   to `'oauth_app_token'`.
#' @param token_validity Validity of the app token in seconds. Defaults to
#' 1 hour (3600s) after which the token and cookie expires.
#' @param redact Logical, whether to redact tokens in UI. Defaults to `TRUE`.
#'
#' @return A configured Shiny app object that allows users to authenticate using
#'   the specified OAuth providers.
#'
#' @examples
#' \dontrun{
#' config <- oauth_shiny_client_config(
#'   oauth_shiny_client_github(),
#'   oauth_shiny_client_google()
#' )
#'
#' oauth_shiny_app_example(config, dark_mode = TRUE)
#' }
#' @export

oauth_shiny_app_example <- function(client_config,
                                    require_auth = TRUE,
                                    key = oauth_shiny_app_passphrase(),
                                    dark_mode = FALSE,
                                    login_ui = oauth_shiny_ui_login(client_config, dark_mode),
                                    logout_ui = oauth_shiny_ui_logout(client_config, dark_mode),
                                    logout_path = "logout",
                                    logout_on_token_expiry = FALSE,
                                    cookie_name = "oauth_app_token",
                                    token_validity = 3600,
                                    redact = TRUE) {
  theme_light <- bslib::bs_theme(primary = "#038053", secondary = "#ccc")
  theme_dark <- bslib::bs_theme(bg = "#121212", fg = "white", primary = "#038053")
  theme <- if (dark_mode) theme_dark else theme_light

  ui <- bslib::page_navbar(
    theme = theme,
    id = "navbar",
    bslib::nav_panel(
      "OAuth Example App",
      shiny::div(
        class = "d-flex align-items-center min-vh-100",
        shiny::div(
          class = "container col-md-10",
          bslib::layout_column_wrap(
            !!!map(names(client_config), oauth_shiny_app_example_client_mod_ui)
          )
        )
      )
    ),
    bslib::nav_spacer(),
    position = "static-top",
    underline = FALSE
  )

  server <- function(input, output, session) {
    token <- shiny::reactive(oauth_shiny_get_app_token(cookie_name, key))

    output$app_token_expiry <- shiny::renderText({
      shiny::req(token())
      cookie_expiry_time <- token()[["exp"]] - unix_time()
      if (cookie_expiry_time > 0) {
        shiny::invalidateLater(1000)
        cookie_expiry <- format_duration(cookie_expiry_time)
      } else {
        cookie_expiry <- "Expired"
      }
      cookie_expiry
    })

    shiny::observeEvent(token(), {
      name <- token()[["name"]] %||% token()[["email"]] %||% token()[["sub"]]
      email <- token()[["email"]] %||% token()[["sub"]]
      provider <- token()[["provider"]] %||% token()[["aud"]]

      bslib::nav_insert(
        "navbar",
        bslib::nav_menu(
          title = shiny::tagList(
            shiny::div(
              class = "d-inline",
              shiny::icon("user", class = "text-primary me-1", lib = "glyphicon"),
              name
            )
          ),
          bslib::nav_item(
            shiny::span(
              class = "dropdown-item-text overflow-hidden",
              shiny::icon("envelope", lib = "glyphicon", class = "me-1"),
              email
            )
          ),
          bslib::nav_item(
            shiny::span(
              class = "dropdown-item-text overflow-hidden",
              shiny::icon("home", lib = "glyphicon", class = "me-1"),
              provider
            )
          ),
          bslib::nav_item(
            shiny::span(
              class = "dropdown-item-text overflow-hidden",
              shiny::icon("time", lib = "glyphicon", class = "me-1"),
              shiny::textOutput("app_token_expiry", inline = TRUE)
            )
          ),
          bslib::nav_item(
            shiny::a(
              shiny::icon("log-in", lib = "glyphicon", class = "me-1"), "Log out",
              href = logout_path,
              class = "dropdown-item-text"
            )
          )
        )
      )
    })

    map(client_config, function(client) {
      oauth_shiny_app_example_client_mod_server(client$name, client, key, redact)
    })
  }

  oauth_shiny_app(
    shiny::shinyApp(ui, server),
    client_config,
    require_auth = require_auth,
    key = key,
    dark_mode = dark_mode,
    login_ui = login_ui,
    logout_ui = logout_ui,
    logout_path = logout_path,
    cookie_name = cookie_name,
    logout_on_token_expiry = logout_on_token_expiry,
    token_validity = token_validity
  )
}
