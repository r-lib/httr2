#' OAuth authentication with device flow
#'
#' @description
#' This uses [oauth_flow_device()] to generate an access token, which is
#' then used to authentication the request with [req_auth_bearer_token()].
#' The token is automatically cached (either in memory or on disk) to minimise
#' the number of times the flow is performed.
#'
#' Learn more about the overall flow in `vignette("oauth")`.
#'
#' @export
#' @inheritParams oauth_flow_password
#' @inheritParams req_oauth_auth_code
#' @returns A modified HTTP [request].
#' @examples
#' client <- oauth_client("example", "https://example.com/get_token")
#' req <- request("https://example.com")
#'
#' req %>% req_oauth_device(client)
req_oauth_device <- function(req, client, auth_url,
                             cache_disk = FALSE,
                             cache_key = NULL,
                             scope = NULL,
                             auth_params = list(),
                             token_params = list()) {

  params <- list(
    client = client,
    auth_url = auth_url,
    scope = scope,
    auth_params = auth_params,
    token_params = token_params
  )
  cache <- cache_choose(client, cache_disk, cache_key)
  req_oauth(req, "oauth_flow_device", params, cache = cache)
}

#' OAuth flow: device
#'
#' @description
#' These functions implement the OAuth device flow, as defined
#' by [rfc8628](https://datatracker.ietf.org/doc/html/rfc8628). It's designed
#' for devices that don't have access to a web browser (if you've ever
#' authenticated an app on your TV, this is probably the flow you've used),
#' but it also works well from within R.
#'
#' This specification allows also some subspecifications:
#' * `oauth_flow_auth_code_pkce()` is also reused here to generate code
#'   verifier, method, and challenge components as needed for PKCE, as
#'   defined in [rfc7636](https://datatracker.ietf.org/doc/html/rfc7636).
#'
#' @inheritParams oauth_flow_auth_code
#' @returns An [oauth_token].
#' @export
#' @family OAuth flows
#' @keywords internal
#' @keywords internal
oauth_flow_device <- function(client,
                              auth_url,
                              pkce = FALSE,
                              scope = NULL,
                              auth_params = list(),
                              token_params = list()) {
  oauth_flow_check("device", client, interactive = is_interactive())

  if (pkce) {
    code <- oauth_flow_auth_code_pkce()
    auth_params$code_challenge <- code$challenge
    auth_params$code_challenge_method <- code$method
    token_params$code_verifier <- code$verifier
  }

  request <- oauth_flow_device_request(client, auth_url, scope, auth_params)

  # User interaction
  # https://datatracker.ietf.org/doc/html/rfc8628#section-3.3
  # Azure provides a message that we might want to print?
  # Google uses verification_url instead of verification_uri
  # verification_uri_complete is optional, it would ship the user
  # code in the uri https://datatracker.ietf.org/doc/html/rfc8628#section-3.2
  url <- request$verification_uri_complete %||% request$verification_uri %||% request$verification_url

  if (is_interactive()) {
    cli::cli_alert("Copy {.strong {request$user_code}} and paste when requested by the browser")
    readline("Press <enter> to proceed:")
    utils::browseURL(url)
  } else {
    inform(glue("Visit <{url}> and enter code {request$user_code}"))
  }

  token <- oauth_flow_device_poll(client, request, token_params)
  if (is.null(token)) {
    cli::cli_abort("Expired without user confirmation; please try again.")
  }

  exec(oauth_token, !!!token)
}

# Device authorization request and response
# https://datatracker.ietf.org/doc/html/rfc8628#section-3.1
# https://datatracker.ietf.org/doc/html/rfc8628#section-3.2
oauth_flow_device_request <- function(client, auth_url, scope, auth_params) {
  req <- request(auth_url)
  req <- req_body_form(req, scope = scope, !!!auth_params)
  req <- oauth_client_req_auth(req, client)
  req <- req_headers(req, Accept = "application/json")

  oauth_flow_fetch(req)
}

# Device Access Token Request
# https://datatracker.ietf.org/doc/html/rfc8628#section-3.4
oauth_flow_device_poll <- function(client, request, token_params) {
  cli::cli_progress_step("Waiting for response from server", spinner = TRUE)

  delay <- request$interval %||% 5
  deadline <- Sys.time() + request$expires_in

  token <- NULL
  while (Sys.time() < deadline) {
    for (i in 1:20) {
      cli::cli_progress_update()
      Sys.sleep(delay / 20)
    }

    tryCatch(
      {
        token <- oauth_client_get_token(client,
          grant_type = "urn:ietf:params:oauth:grant-type:device_code",
          device_code = request$device_code,
          !!!token_params
        )
        break
      },
      httr2_oauth_authorization_pending = function(err) {},
      httr2_oauth_slow_down = function(err) {
        delay <<- delay + 5
      }
    )
  }
  cli::cli_progress_done()
  token
}
