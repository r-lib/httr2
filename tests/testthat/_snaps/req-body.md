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

# can't change body type

    Code
      req %>% req_body_json(list(x = 1))
    Condition
      Error in `req_body_json()`:
      ! Can't change body type from raw to json.
      i You must use only one type of `req_body_*()` per request.

