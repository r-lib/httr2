# printing token redacts access and refresh token

    Code
      oauth_token(access_token = "secret", refresh_token = "secret")
    Message <cliMessage>
      <httr2_token>
        access_token: <REDACTED>
        token_type: bearer
        refresh_token: <REDACTED>

