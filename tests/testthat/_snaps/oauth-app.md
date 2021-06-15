# can check app has needed pieces

    Code
      oauth_flow_check("test", client, is_confidential = TRUE)
    Error <rlang_error>
      Can't use this `app` with OAuth 2.0 test flow
      * `app` must have a confidential client (i.e. `client_secret` is required)
    Code
      oauth_flow_check("test", client, interactive = TRUE)
    Error <rlang_error>
      OAuth 2.0 test flow requires an interactive session

# client has useful print method

    Code
      oauth_client("x", token_url = "http://example.com")
    Message <cliMessage>
      <httr2_oauth_client>
      name: bf27508f7925b06bf28a10f3805351ab
      id: x
      token_url: http://example.com
      auth: oauth_client_req_auth_body
    Code
      oauth_client("x", secret = "SECRET", token_url = "http://example.com")
    Message <cliMessage>
      <httr2_oauth_client>
      name: bf27508f7925b06bf28a10f3805351ab
      id: x
      secret: <REDACTED>
      token_url: http://example.com
      auth: oauth_client_req_auth_body

