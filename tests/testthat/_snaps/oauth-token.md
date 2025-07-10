# new token computes expires_at

    Code
      token
    Output
      <httr2_token>
      * token_type  : "bearer"
      * access_token: <REDACTED>
      * expires_at  : "2025-02-19 21:20:10"

# printing token redacts access, id and refresh token

    Code
      oauth_token(access_token = "secret", refresh_token = "secret", id_token = "secret")
    Output
      <httr2_token>
      * token_type   : "bearer"
      * access_token : <REDACTED>
      * refresh_token: <REDACTED>
      * id_token     : <REDACTED>

