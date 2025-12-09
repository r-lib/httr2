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
      oauth_client("abc", "http://x.com", key = "abc", auth = "jwt_sig")
    Condition
      Error in `oauth_client()`:
      ! `auth = 'jwt_sig'` requires a claim specification in `auth_params`.
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
      * name     : "bf27508f7925b06bf28a10f3805351ab"
      * id       : "x"
      * token_url: "http://example.com"
      * auth     : "oauth_client_req_auth_body"
    Code
      oauth_client("x", url, secret = "SECRET")
    Output
      <httr2_oauth_client>
      * name     : "bf27508f7925b06bf28a10f3805351ab"
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
      * name     : "bf27508f7925b06bf28a10f3805351ab"
      * id       : "x"
      * token_url: "http://example.com"
      * auth     : <function>

# validates claim

    Code
      oauth_client("test", "http://example.com", key = "abc", auth_params = list(
        claim = "123"))
    Condition
      Error in `oauth_client()`:
      ! claim in `auth_params` must be a list or function.

---

    Code
      oauth_client("test", "http://example.com", key = "abc", auth_params = list(
        claim = jwt_claim()))
    Output
      <httr2_oauth_client>
      * name       : "b3d60321e62eb364e9c8dc12ffeec242"
      * id         : "test"
      * key        : <REDACTED>
      * token_url  : "http://example.com"
      * auth       : "oauth_client_req_auth_jwt_sig"
      * auth_params: <list>

---

    Code
      oauth_client("test", "http://example.com", key = "abc", auth_params = list(
        claim = jwt_claim))
    Output
      <httr2_oauth_client>
      * name       : "b3d60321e62eb364e9c8dc12ffeec242"
      * id         : "test"
      * key        : <REDACTED>
      * token_url  : "http://example.com"
      * auth       : "oauth_client_req_auth_jwt_sig"
      * auth_params: <list>

