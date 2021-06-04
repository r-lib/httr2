#' OAuth flow: user password
#'
#' This function implements the OAuth resource owner password flow, as defined
#' by [rfc6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3),
#' Section 4.3. It allows the user to supply their password once, exchanging
#' it for an access token that can be cached locally.
#'
#' @inheritParams oauth_flow_auth_code
#' @param username,password Pair of user name and password. Note that you
#'   should avoid entering the password directly when calling this function
#'   as it will be captured by `.Rhistory`. Instead, leave it unset and
#'   the default behaviour will prompt you for it interactively.
#' @export
#' @family OAuth flows
oauth_flow_password <- function(app,
                                username,
                                password = NULL,
                                scope = NULL,
                                token_params = list()
) {
  oauth_flow_check_app(app,
    flow = "resource owner password credentials",
    endpoints = "token",
    interactive = is.null(password)
  )
  check_string(username, "`username`")
  if (is.null(password)) {
    check_installed("askpass")
    password <- askpass::askpass()
  }
  check_string(password, "`password`")

  oauth_flow_access_token(app,
    grant_type = "password",
    username = username,
    password = password,
    scope = scope,
    !!!token_params
  )
}
