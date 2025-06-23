# local_mock and with_mock are deprecated

    Code
      local_mock(function(req) response(404))
    Condition
      Warning:
      `local_mock()` was deprecated in httr2 1.1.0.
      i Please use `local_mocked_responses()` instead.
    Code
      . <- with_mock(NULL, function(req) response(404))
    Condition
      Error:
      ! `with_mock()` was deprecated in httr2 1.1.0 and is now defunct.
      i Please use `with_mocked_responses()` instead.

# validates inputs

    Code
      local_mocked_responses(function(foo) { })
    Condition
      Error in `local_mocked_responses()`:
      ! `mock` must have the argument `req`; it currently has `foo`.
    Code
      local_mocked_responses(10)
    Condition
      Error in `local_mocked_responses()`:
      ! `mock` must be function, list, or NULL, not the number 10.

