# desktop style can't run in hosted environment

    Code
      oauth_flow_auth_code(client, "http://example.com", type = "desktop")
    Condition
      Error in `oauth_flow_auth_code()`:
      ! Only type='web' is supported in the current session

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
      i Learn more at <uri>.
    Code
      oauth_flow_auth_code_parse(query3, "abc")
    Condition
      Error in `oauth_flow_auth_code_parse()`:
      ! Authentication failure: state does not match.

