# printing token redacts access and refresh token

    Code
      oauth_token(access_token = "secret", refresh_token = "secret")
    Message <cliMessage>
      <httr2_token>
      token_type: bearer
      access_token: <REDACTED>
      refresh_token: <REDACTED>

