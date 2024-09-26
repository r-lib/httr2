#' Create an OAuth Shiny UI Login Page
#'
#' This function creates the Shiny UI for the OAuth login page, allowing users
#' to log in with their preferred OAuth provider. The UI can be customized for
#' dark mode.
#'
#' @param oauth_shiny_client_config A list of client configurations for OAuth
#'   providers.
#' @param dark_mode A logical value indicating whether to use dark mode.
#'   Defaults to `FALSE`.
#'
#' @return A Shiny UI object representing the login page.
#' @export
oauth_shiny_ui_login <- function(oauth_shiny_client_config, dark_mode = FALSE) {
  dep <- htmltools::htmlDependency(
    name = "oauth-ui",
    version = "1.0",
    src = "shiny",
    package = "httr2",
    all_files = TRUE,
    stylesheet = "style.css"
  )

  ui <- shiny::fluidPage(
    if (dark_mode) shiny::tags$style("body {background-color: black;}"),
    shiny::fluidRow(
      shiny::div(
        class = "full-page-container center-content",
        shiny::wellPanel(
          class = paste("login-panel", ifelse(dark_mode, "dark-panel", "")),
          shiny::h2("Welcome"),
          shiny::p("Login with your preferred provider"),
          lapply(oauth_shiny_client_config, oauth_shiny_ui_login_button, dark_mode = dark_mode)
        )
      )
    )
  )

  shiny::tagList(dep, ui)
}

oauth_shiny_ui_login_button <- function(client, dark_mode = FALSE) {
  if (client$auth_provider) {
    ui <- if (dark_mode) client$login_button_dark else client$login_button
  } else {
    ui <- NULL
  }
}

#' Create an OAuth Shiny UI Logout Page
#'
#' This function creates the Shiny UI for the OAuth logout page, displaying a
#' message that the user has successfully logged out.
#'
#' @param oauth_shiny_client_config A list of client configurations for OAuth
#'   providers.
#' @param dark_mode A logical value indicating whether to use dark mode.
#'   Defaults to `FALSE`.
#'
#' @return A Shiny UI object representing the logout page.
#' @export
oauth_shiny_ui_logout <- function(oauth_shiny_client_config, dark_mode = FALSE) {
  dep <- htmltools::htmlDependency(
    name = "oauth-ui",
    version = "1.0",
    src = "shiny",
    package = "httr2",
    all_files = TRUE,
    stylesheet = "style.css"
  )

  ui <- shiny::fluidPage(
    if (dark_mode) shiny::tags$style("body {background-color: black;}"),
    shiny::div(
      class = ifelse(dark_mode, "dark-mode", ""),
      shiny::fluidRow(
        shiny::div(
          class = "full-page-container center-content",
          shiny::wellPanel(
            class = paste("login-panel", ifelse(dark_mode, "dark-panel", "")),
            shiny::h2("Logged out"),
            shiny::p("You are successfully logged out"),
            lapply(oauth_shiny_client_config, oauth_shiny_ui_login_button, dark_mode = dark_mode)
          )
        )
      )
    )
  )
  shiny::tagList(dep, ui)
}

#' Create a Custom OAuth Shiny UI Login Button
#'
#' This function creates a custom login button for an OAuth provider, allowing
#' customization of the button's appearance.
#'
#' @param path The URL path for the OAuth login.
#' @param title The title to display on the button.
#' @param logo The file path or SVG code for the logo to display on the button.
#' @param theme The theme of the button, either "light" or "dark". Defaults to
#'   "light".
#'
#' @return A Shiny UI object representing the login button.
#' @export
oauth_shiny_ui_button <- function(path,
                                  title,
                                  logo = NULL,
                                  theme = c("light", "dark")) {
  theme <- match.arg(theme)

  # Set button class based on theme
  button_class <- if (theme == "light") {
    "gsi-material-button"
  } else {
    "gsi-material-button dark-mode"
  }

  # Determine image source
  if (!is.null(logo)) {
    # Attempt to encode the logo (as file or SVG code)
    src <- base64_img_encode(logo)
  } else {
    src <- NULL
  }

  # Create image element if source is available
  img <- if (!is.null(src)) {
    shiny::div(
      class = "gsi-material-button-icon",
      shiny::img(
        src = src,
        class = "gsi-material-button-icon-img",
        height = 20
      )
    )
  } else {
    shiny::div(class = "gsi-material-button-icon")
  }

  # Return the Shiny UI button component
  shiny::tagList(
    htmltools::htmlDependency(
      name = "oauth-ui",
      version = "1.0",
      src = "shiny",
      package = "httr2",
      all_files = TRUE,
      stylesheet = "style.css"
    ),
    shiny::div(
      class = "gsi-material-button-container",
      shiny::a(
        href = path,
        shiny::tags$button(
          class = button_class,
          shiny::div(class = "gsi-material-button-state"),
          shiny::div(
            class = "gsi-material-button-content-wrapper",
            img,
            shiny::span(class = "gsi-material-button-contents", title),
            shiny::span(style = "display: none;", title)
          )
        )
      )
    )
  )
}


oauth_shiny_ui_button_apple <- function(path = "login/apple", title = "Sign in with Apple") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/apple.svg", package = "httr2"),
    theme = "light"
  )
}

oauth_shiny_ui_button_apple_dark <- function(path = "login/apple", title = "Sign in with Apple") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/apple-dark.svg", package = "httr2"),
    theme = "dark"
  )
}

oauth_shiny_ui_button_google <- function(path = "login/google", title = "Sign in with Google") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/google.svg", package = "httr2"),
    theme = "light"
  )
}

oauth_shiny_ui_button_google_dark <- function(path = "login/google", title = "Sign in with Google") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/google.svg", package = "httr2"),
    theme = "dark"
  )
}

oauth_shiny_ui_button_facebook <- function(path = "login/facebook", title = "Sign in with Facebook") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/facebook.svg", package = "httr2"),
    theme = "light"
  )
}

oauth_shiny_ui_button_facebook_dark <- function(path = "login/facebook", title = "Sign in with Facebook") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/facebook.svg", package = "httr2"),
    theme = "dark"
  )
}

oauth_shiny_ui_button_github <- function(path = "login/github", title = "Sign in with Github") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/github.svg", package = "httr2"),
    theme = "light"
  )
}

oauth_shiny_ui_button_github_dark <- function(path = "login/github", title = "Sign in with Github") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/github-dark.svg", package = "httr2"),
    theme = "dark"
  )
}

oauth_shiny_ui_button_microsoft <- function(path = "login/microsoft", title = "Sign in with Microsoft") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/microsoft.svg", package = "httr2"),
    theme = "light"
  )
}

oauth_shiny_ui_button_microsoft_dark <- function(path = "login/microsoft", title = "Sign in with Microsoft") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/microsoft.svg", package = "httr2"),
    theme = "dark"
  )
}

oauth_shiny_ui_button_spotify <- function(path = "login/spotify", title = "Sign in with Spotify") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/spotify.svg", package = "httr2"),
    theme = "light"
  )
}

oauth_shiny_ui_button_spotify_dark <- function(path = "login/spotify", title = "Sign in with Spotify") {
  oauth_shiny_ui_button(
    path = path,
    title = title,
    logo = system.file("shiny/spotify.svg", package = "httr2"),
    theme = "dark"
  )
}

render_static_html_document <- function(ui) {
  lang <- attr(ui, "lang", exact = TRUE) %||% "en"
  if (!(inherits(ui, "shiny.tag") && ui$name == "body")) {
    ui <- shiny::tags$body(ui)
  }
  doc <- htmltools::htmlTemplate(
    system.file("shiny", "default.html", package = "httr2"),
    lang = lang,
    body = ui,
    document_ = TRUE
  )
  htmltools::renderDocument(doc, processDep = shiny::createWebDependency)
}
