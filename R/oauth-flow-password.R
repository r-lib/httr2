#' OAuth with username and password
#'
#' @description
#' This function implements the OAuth **resource owner password flow**, as
#' defined by `r rfc(6749, 4.3)`. It allows the user to supply their password
#' once, exchanging it for an access token that can be cached locally.
#'
#' Learn more about the overall flow in `vignette("oauth")`.
#'
#' @export
#' @family OAuth flows
#' @inheritParams req_oauth_auth_code
#' @inheritParams req_auth_basic
#' @returns `req_oauth_password()` returns a modified HTTP [request] that will
#'   use OAuth; `oauth_flow_password()` returns an [oauth_token].
#' @examples
#' req_auth <- function(req) {
#'   req_oauth_password(req,
#'     client = oauth_client("example", "https://example.com/get_token"),
#'     username = "username"
#'   )
#' }
#' if (interactive()) {
#'   request("https://example.com") %>%
#'     req_auth()
#' }
req_oauth_password <- function(req,
                               client,
                               username,
                               password = NULL,
                               scope = NULL,
                               token_params = list(),
                               cache_disk = FALSE,
                               cache_key = username) {

  password <- check_password(password)
  params <- list(
    client = client,
    username = username,
    password = password,
    scope = scope,
    token_params = token_params
  )
  cache <- cache_choose(client, cache_disk = cache_disk, cache_key = cache_key)
  req_oauth(req, "oauth_flow_password", params, cache = cache)
}

#' @export
#' @rdname req_oauth_password
oauth_flow_password <- function(client,
                                username,
                                password = NULL,
                                scope = NULL,
                                token_params = list()) {
  oauth_flow_check("resource owner password credentials", client,
    interactive = is.null(password)
  )
  check_string(username)
  password <- check_password(password)

  oauth_client_get_token(client,
    grant_type = "password",
    username = username,
    password = password,
    scope = scope,
    !!!token_params
  )
}

check_password <- function(password, call = caller_env()) {
  if (is.null(password)) {
    check_installed("askpass", call = call)
    password <- askpass::askpass()
  }
  check_string(password, call = call)
  password
}
