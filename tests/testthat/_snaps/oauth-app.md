# oauth_app checks its inputs

    Code
      oauth_app(1)
    Error <rlang_error>
      `client` must be an OAuth client created with `oauth_client()`
    Code
      client <- oauth_client("id")
      oauth_app(client, endpoints = 1)
    Error <rlang_error>
      `endpoints` must be a named character vector
    Code
      oauth_app(client, endpoints = c(x = "x"))
    Error <rlang_error>
      `endpoints` must contain a token endpoint
    Code
      oauth_app(client, endpoints = c(token = "test"), auth = "header")
    Error <rlang_error>
      `auth = 'header' requires a client with a secret

# can check app has needed pieces

    Code
      oauth_flow_check_app(app, "test", is_confidential = TRUE)
    Error <rlang_error>
      Can't use this `app` with OAuth 2.0 test flow
      * `app` must have a confidential client (i.e. `client_secret` is required)
    Code
      oauth_flow_check_app(app, "test", endpoints = "foo")
    Error <rlang_error>
      Can't use this `app` with OAuth 2.0 test flow
      * `app` lacks endpoints 'foo'
    Code
      oauth_flow_check_app(app, "test", interactive = TRUE)
    Error <rlang_error>
      OAuth 2.0 test flow requires an interactive session

# client has useful print method

    Code
      oauth_client("x")
    Message <cliMessage>
      <httr2_oauth_client>
      id: x
      secret: <REDACTED>
    Code
      oauth_client("x", "x")
    Message <cliMessage>
      <httr2_oauth_client>
      id: x
      secret: <REDACTED>

