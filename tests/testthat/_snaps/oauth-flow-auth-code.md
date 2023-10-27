# desktop style can't run in hosted environment

    Code
      oauth_flow_auth_code(client, "http://localhost")
    Condition
      Error in `oauth_flow_auth_code()`:
      ! Can't use localhost `redirect_uri` in a hosted environment.

# old args are deprecated

    Code
      redirect <- normalize_redirect_uri("http://localhost", port = 1234)
    Condition
      Warning:
      The `port` argument of `oauth_flow_auth_code()` is deprecated as of httr2 1.0.0.
      i Please use the `redirect_uri` argument instead.

---

    Code
      redirect <- normalize_redirect_uri("http://x.com", host_name = "y.com")
    Condition
      Warning:
      The `host_name` argument of `oauth_flow_auth_code()` is deprecated as of httr2 1.0.0.
      i Please use the `redirect_uri` argument instead.

---

    Code
      redirect <- normalize_redirect_uri("http://x.com", host_ip = "y.com")
    Condition
      Warning:
      The `host_ip` argument of `oauth_flow_auth_code()` is deprecated as of httr2 1.0.0.

# forwards oauth error

    Code
      oauth_flow_auth_code_parse(query1, "abc")
    Condition
      Error in `oauth_flow_auth_code_parse()`:
      ! OAuth failure [123]
      * A bad error
    Code
      oauth_flow_auth_code_parse(query2, "abc")
    Condition
      Error in `oauth_flow_auth_code_parse()`:
      ! OAuth failure [123]
      * A bad error
      i Learn more at <http://example.com>.
    Code
      oauth_flow_auth_code_parse(query3, "abc")
    Condition
      Error in `oauth_flow_auth_code_parse()`:
      ! Authentication failure: state does not match.

