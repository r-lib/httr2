# check argument types before caching

    Code
      resp_body_json(1)
    Condition
      Error in `resp_body_json()`:
      ! `resp` must be an HTTP response object, not the number 1.
    Code
      resp_body_xml(1)
    Condition
      Error in `resp_body_xml()`:
      ! `resp` must be an HTTP response object, not the number 1.

# content types are checked

    Code
      resp_body_json(req_perform(request_test("/xml")))
    Condition
      Error in `example_url()`:
      ! The package "webfakes" is required.
    Code
      resp_body_xml(req_perform(request_test("/json")))
    Condition
      Error in `example_url()`:
      ! The package "webfakes" is required.

