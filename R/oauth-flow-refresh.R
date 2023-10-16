#' OAuth with a refresh token
#'
#' @description
#' Authenticate using a **refresh token**, following the process described in
#' `r rfc(6749, 6)`.
#'
#' This technique is primarily useful for testing: you can manually retrieve
#' a OAuth token using another OAuth flow (e.g. with [oauth_flow_auth_code()]),
#' extract the refresh token from the result, and then save in an environment
#' variable for use in automated tests.
#'
#' When requesting an access token, the server may also return a new refresh
#' token. If this happens, `oauth_flow_refresh()` will warn, and you'll have
#' retrieve a new update refresh token and update the stored value. If you find
#' this happening a lot, it's a sign that you should be using a different flow
#' in your automated tests.
#'
#' Learn more about the overall OAuth authentication flow in `vignette("oauth")`.
#'
#' @inheritParams req_oauth_auth_code
#' @param refresh_token A refresh token. This is equivalent to a password
#'   so shouldn't be typed into the console or stored in a script. Instead,
#'   we recommend placing in an environment variable; the default behaviour
#'   is to look in `HTTR2_REFRESH_TOKEN`.
#' @returns `req_oauth_refresh()` returns a modified HTTP [request] that will
#'   use OAuth; `oauth_flow_refresh()` returns an [oauth_token].
#' @family OAuth flows
#' @export
#' @examples
#' client <- oauth_client("example", "https://example.com/get_token")
#' req <- request("https://example.com")
#' req |> req_oauth_refresh(client)
req_oauth_refresh <- function(req,
                              client,
                              refresh_token = Sys.getenv("HTTR2_REFRESH_TOKEN"),
                              scope = NULL,
                              token_params = list()) {

  params <- list(
    client = client,
    refresh_token = refresh_token,
    scope = scope,
    token_params = token_params
  )
  cache <- cache_mem(client, refresh_token)

  req_oauth(req, "oauth_flow_refresh", params, cache = cache)
}

#' @export
#' @rdname req_oauth_refresh
oauth_flow_refresh <- function(client,
                               refresh_token = Sys.getenv("HTTR2_REFRESH_TOKEN"),
                               scope = NULL,
                               token_params = list()) {
  oauth_flow_check("refresh", client)
  token <- token_refresh(client,
    refresh_token = refresh_token,
    scope = scope,
    token_params = token_params
  )

  # Should generally do this automatically, but in this workflow the token will
  # often be stored in an env var or similar
  if (!is.null(token$refresh_token) && token$refresh_token != refresh_token) {
    warn("Refresh token has changed! Please update stored value")
  }

  token
}
