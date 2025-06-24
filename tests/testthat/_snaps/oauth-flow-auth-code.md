# desktop style can't run in hosted environment

    Code
      oauth_flow_auth_code(client, "http://localhost")
    Condition
      Error in `oauth_flow_auth_code()`:
      ! Can't use localhost `redirect_uri` in a hosted environment.

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

