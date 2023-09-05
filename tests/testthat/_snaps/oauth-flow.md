# turns oauth errors to R errors

    Code
      oauth_flow_fetch(req, "test")
    Condition
      Error:
      ! OAuth failure [1]
      * abc

# userful errors if response isn't parseable

    Code
      oauth_flow_parse(resp1, "test")
    Condition
      Error:
      ! Failed to parse response from `test` url.
      * Response type was "text/plain" not "application/json".
    Code
      oauth_flow_parse(resp2, "test")
    Condition
      Error:
      ! Failed to parse response from `test` url.
      * Did not contain `access_token`, `device_code`, or `error` field.

# returns body if known good structure

    Code
      oauth_flow_parse(resp, "test")
    Condition
      Error:
      ! OAuth failure [10]

