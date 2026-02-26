# can't change body type

    Code
      req_body_json(req, list(x = 1))
    Condition
      Error in `req_body_json()`:
      ! Can't change body type from raw to json.
      i You must use only one type of `req_body_*()` per request.

# errors on invalid input

    Code
      req_body_file(request_test(), 1)
    Condition
      Error in `example_url()`:
      ! The package "webfakes" is required.
    Code
      req_body_file(request_test(), "doesntexist")
    Condition
      Error in `example_url()`:
      ! The package "webfakes" is required.
    Code
      req_body_file(request_test(), ".")
    Condition
      Error in `example_url()`:
      ! The package "webfakes" is required.

# non-json type errors

    Code
      req_body_json(request_test(), mtcars, type = "application/xml")
    Condition
      Error in `example_url()`:
      ! The package "webfakes" is required.

