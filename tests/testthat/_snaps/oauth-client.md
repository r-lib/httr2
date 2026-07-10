# can check app has needed pieces

    Code
      oauth_flow_check("test", NULL)
    Condition
      Error:
      ! `client` must be an OAuth client created with `oauth_client()`.
    Code
      oauth_flow_check("test", client, is_confidential = TRUE)
    Condition
      Error:
      ! Can't use this `app` with OAuth 2.0 test flow.
      i `app` must have a confidential client (i.e. `client_secret` is required).
    Code
      oauth_flow_check("test", client, interactive = TRUE)
    Condition
      Error:
      ! OAuth 2.0 test flow requires an interactive session

# checks auth types have needed args

    Code
      oauth_client("abc", "http://x.com", auth = "header")
    Condition
      Error in `oauth_client()`:
      ! `auth = 'header'` requires a `secret`.
    Code
      oauth_client("abc", "http://x.com", auth = "jwt_sig")
    Condition
      Error in `oauth_client()`:
      ! `auth = 'jwt_sig'` requires a `key`.
    Code
      oauth_client("abc", "http://x.com", auth = 123)
    Condition
      Error in `oauth_client()`:
      ! `auth` must be a string or function.

# client has useful print method

    Code
      oauth_client("x", url)
    Output
      <httr2_oauth_client>
      * name     : "9758a2659d8a24b1be8a873ab9e4da84"
      * id       : "x"
      * token_url: "http://example.com"
      * auth     : "oauth_client_req_auth_body"
    Code
      oauth_client("x", url, secret = "SECRET")
    Output
      <httr2_oauth_client>
      * name     : "9758a2659d8a24b1be8a873ab9e4da84"
      * id       : "x"
      * secret   : <REDACTED>
      * token_url: "http://example.com"
      * auth     : "oauth_client_req_auth_body"
    Code
      oauth_client("x", url, auth = function(...) {
        xxx
      })
    Output
      <httr2_oauth_client>
      * name     : "9758a2659d8a24b1be8a873ab9e4da84"
      * id       : "x"
      * token_url: "http://example.com"
      * auth     : <function>

# metadata is validated and token_url must be resolvable

    Code
      oauth_client("id")
    Condition
      Error in `oauth_client()`:
      ! Must supply `token_url`, or `metadata` that advertises a token_endpoint.
    Code
      oauth_client("id", metadata = metadata)
    Condition
      Error in `oauth_client()`:
      ! Must supply `token_url`, or `metadata` that advertises a token_endpoint.
    Code
      oauth_client("id", token_url = "https://x.com", metadata = list())
    Condition
      Error in `oauth_client()`:
      ! `metadata` must be created with `oauth_server_metadata()`.

# jwt_sig auth requires a claim

    Code
      oauth_client_req_auth(request("http://example.com"), client)
    Condition
      Error in `oauth_client_req_auth_jwt_sig()`:
      ! `auth = 'jwt_sig'` requires a `claim` in `auth_params`.

