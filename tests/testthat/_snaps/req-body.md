# errors if file doesn't exist

    Code
      req_body_file(request_test(), "doesntexist", type = "text/plain")
    Condition
      Error in `req_body_file()`:
      ! `path` ('doesntexist') does not exist.

# non-json type errors

    Code
      req_body_json(request_test(), mtcars, type = "application/xml")
    Condition
      Error in `req_body_json()`:
      ! Unexpected content type "application/xml".
      * Expecting type "application/json" or suffix "json".

