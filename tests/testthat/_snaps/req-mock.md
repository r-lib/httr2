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

