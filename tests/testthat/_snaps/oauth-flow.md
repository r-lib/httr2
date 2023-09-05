# errors if response isn't json

    Code
      oauth_flow_fetch(req)
    Condition
      Error in `oauth_flow_fetch()`:
      ! Failed to process response from "token" endpoint.

# forwards turns oauth errors to R errors

    Code
      oauth_flow_fetch(req)
    Condition
      Error in `oauth_flow_fetch()`:
      ! OAuth failure [1]
      * abc

