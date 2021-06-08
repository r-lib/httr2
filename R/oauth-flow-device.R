#' OAuth authentication with device flow
#'
#' @description
#' This uses [oauth_flow_device()] to generate an access token, which is
#' then used to authentication the request with [req_auth_bearer_token()].
#' The token is automatically cached (either in memory or on disk) to minimise
#' the number of times the flow is performed.
#'
#' @export
#' @inheritParams oauth_flow_password
#' @inheritParams req_oauth_auth_code
req_oauth_device <- function(req, app,
                             cache_disk = FALSE,
                             cache_key = NULL,
                             scope = NULL,
                             auth_params = list(),
                             token_params = list()) {

  params <- list(
    app = app,
    scope = scope,
    auth_params = auth_params,
    token_params = token_params
  )
  cache <- cache_choose(app, cache_disk, cache_key)
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
#' @inheritParams oauth_flow_auth_code
#' @export
#' @family OAuth flows
oauth_flow_device <- function(app,
                              scope = NULL,
                              auth_params = list(),
                              token_params = list()) {
  oauth_flow_check_app(app,
    flow = "device",
    endpoints = "device_authorization"
  )

  request <- oauth_flow_device_request(app, scope, auth_params)

  # User interaction
  # https://datatracker.ietf.org/doc/html/rfc8628#section-3.3
  # Azure provides a message that we might want to print?
  # Google uses verification_url instead of verification_uri
  if (is_interactive() && has_name(request, "verification_uri_complete")) {
    inform(glue("Use code {request$user_code}"))
    utils::browseURL(request$verification_uri_complete)
  } else {
    url <- request$verification_uri %||% request$verification_url
    inform(glue("Visit <{url}> and enter code {request$user_code}"))
  }

  token <- oauth_flow_device_poll(app, request, token_params)
  if (is.null(token)) {
    abort("Expired without user confirmation; please try again.")
  }

  exec(oauth_token, !!!token)
}

# Device authorization request and response
# https://datatracker.ietf.org/doc/html/rfc8628#section-3.1
# https://datatracker.ietf.org/doc/html/rfc8628#section-3.2
oauth_flow_device_request <- function(app, scope, auth_params) {
  url <- app_endpoint(app, "device_authorization")

  params <- list2(
    client_id = app$client$id,
    scope = scope,
    !!!auth_params
  )
  req <- req(url)
  req <- req_body_form(req, params)
  # req <- req_auth_oauth_client(req, app)
  req <- req_headers(req, Accept = "application/json")

  resp <- req_fetch(req)
  resp_body_json(resp)
}

# Device Access Token Request
# https://datatracker.ietf.org/doc/html/rfc8628#section-3.4
oauth_flow_device_poll <- function(app, request, token_params) {
  delay <- request$interval %||% 5
  deadline <- Sys.time() + request$expires_in

  token <- NULL
  while (Sys.time() < deadline) {
    sys_sleep(delay) # Waiting for confirmation :spinner

    tryCatch(
      {
        token <- oauth_flow_access_token(app,
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

  token
}
