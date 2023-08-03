#' OAuth authentication with a refresh token
#'
#' @description
#' This uses [oauth_flow_refresh()] to generate an access token, which is
#' then used to authenticate the request with [req_auth_bearer_token()].
#' This is primarily useful for testing: you can manually execute another OAuth
#' flow (e.g. by calling [oauth_flow_auth_code()] or [oauth_flow_device()]),
#' extract the refresh token from the result, and then save in an environment
#' variable for future use in automated tests.
#'
#' When requesting an access token, the server may also return a new refresh
#' token. If this happens, `oauth_flow_refresh()` will warn, and you'll have to
#' update your stored refresh token.
#'
#' @export
#' @inheritParams req_perform
#' @inheritParams oauth_flow_refresh
#' @returns A modified HTTP [request].
#' @examples
#' client <- oauth_client("example", "https://example.com/get_token")
#' req <- request("https://example.com")
#' req %>% req_oauth_refresh(client)
req_oauth_refresh <- function(req, client,
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

#' OAuth flow: refresh token
#'
#' @description
#' This function generates an access token from a refresh token, following
#' the process described in
#' [rfc6749](https://datatracker.ietf.org/doc/html/rfc6749#section-6),
#' Section 6. Warns if the refresh returns a new refresh token, see
#' [req_oauth_refresh()] for details.
#'
#' @inheritParams oauth_flow_auth_code
#' @param refresh_token A refresh token. This is equivalent to a password
#'   so shouldn't be typed into the console or stored in a script. Instead,
#'   we recommend placing in an environment variable; the default behaviour
#'   is to look in `HTTR2_REFRESH_TOKEN`.
#' @family OAuth flows
#' @returns An [oauth_token].
#' @export
#' @keywords internal
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
