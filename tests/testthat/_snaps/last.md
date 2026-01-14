# can get json response

    Code
      last_response_json()
    Output
      {
        "x": 1
      }
    Code
      last_response_json(pretty = FALSE)
    Output
      {"x":1}

# can get json request

    Code
      last_request_json()
    Output
      {
        "x": 1
      }
    Code
      last_request_json(pretty = FALSE)
    Output
      {"x":1}

# useful errors if not json request/response

    Code
      last_request_json()
    Condition
      Error in `last_request_json()`:
      ! Last request doesn't have a JSON body.
    Code
      last_response_json()
    Condition
      Error in `last_response_json()`:
      ! Unexpected content type "application/xml".
      * Expecting type "application/json" or suffix "json".

# useful errors if no last request/response

    Code
      last_request_json()
    Condition
      Error in `last_request_json()`:
      ! No request has been made yet.
    Code
      last_response_json()
    Condition
      Error in `last_response_json()`:
      ! No request has been made successfully yet.

