oauth_flow_device <- function(app,
                              scope = NULL,
                              auth_params = list(),
                              token_params = list()) {
  oauth_flow_check_app(app,
    flow = "device_flow",
    endpoints = "device_authorization"
  )

  # Device Authorization Request
  # https://datatracker.ietf.org/doc/html/rfc8628#section-3.1
  #
  # Can require authentication, in which case client_id is not needed
  url <- app_endpoint(app, "device_authorization")

  params <- list2(
    client_id = app$client,
    scope = scope,
    !!!auth_params
  )
  req <- req(url)
  req <- req_body_form(req, params)
  req <- req_auth_oauth_client(req, app)
  resp <- req_fetch(req)
  # Device Authorization Response
  # https://datatracker.ietf.org/doc/html/rfc8628#section-3.2
  body <- resp_body_json(resp)

  # User interaction
  # https://datatracker.ietf.org/doc/html/rfc8628#section-3.3
  # Azure provides a message that we might want to print?
  if (is_interactive() && has_name(body, "verification_uri_complete")) {
    inform(glue("Use code {body$user_code}"))
    utils::browseURL(body$verification_uri_complete)
  } else {
    inform(glue("Visit <{body$verification_uri}> and enter code {body$user_code}"))
  }

  # Device Access Token Request
  # https://datatracker.ietf.org/doc/html/rfc8628#section-3.4
  token <- NULL
  delay <- body$interval %||% 5
  deadline <- Sys.time() + body$expires_in

  repeat {
    sys_sleep(delay) # Waiting for confirmation :spinner
    if (Sys.time() > deadline) {
      abort("Expired without user confirmation; please try again.")
    }

    tryCatch(
      {
        token <- oauth_flow_access_token(app,
          grant_type = "urn:ietf:params:oauth:grant-type:device_code",
          device_code = body$device_code,
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
