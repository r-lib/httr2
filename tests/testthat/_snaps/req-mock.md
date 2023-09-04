# local_mock and with_mock are deprecated

    Code
      local_mock(~ response(404))
    Condition
      Warning:
      `local_mock()` was deprecated in httr2 0.3.0.
      i Please use `local_mocked_responses()` instead.
    Code
      . <- with_mock(NULL, ~ response(404))
    Condition
      Warning:
      `with_mock()` was deprecated in httr2 0.3.0.
      i Please use `with_mocked_responses()` instead.

