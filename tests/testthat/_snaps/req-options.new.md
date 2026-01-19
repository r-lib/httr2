# validates inputs

    Code
      req_timeout(request_test(), "x")
    Condition
      Error in `example_url()`:
      ! The package "webfakes" is required.
    Code
      req_timeout(request_test(), 0)
    Condition
      Error in `example_url()`:
      ! The package "webfakes" is required.

