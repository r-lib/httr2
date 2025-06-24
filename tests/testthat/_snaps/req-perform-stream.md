# req_perform_stream() has been soft deprecated

    Code
      . <- req_perform_stream(req, function(x) NULL)
    Condition
      Warning:
      `req_perform_stream()` was deprecated in httr2 1.2.0.
      i Please use `req_perform_connection()` instead.

# req_perform_stream checks its inputs

    Code
      req_perform_stream(1)
    Condition
      Error in `req_perform_stream()`:
      ! `req` must be an HTTP request object, not the number 1.
    Code
      req_perform_stream(req, 1)
    Condition
      Error in `req_perform_stream()`:
      ! `callback` must be a function, not the number 1.
    Code
      req_perform_stream(req, callback, timeout_sec = -1)
    Condition
      Error in `req_perform_stream()`:
      ! `timeout_sec` must be a number larger than or equal to 0, not the number -1.
    Code
      req_perform_stream(req, callback, buffer_kb = "x")
    Condition
      Error in `req_perform_stream()`:
      ! `buffer_kb` must be a number, not the string "x".

# as_round_function checks its inputs

    Code
      as_round_function(1)
    Condition
      Error:
      ! `round` must be "byte", "line" or a function.
    Code
      as_round_function("bytes")
    Condition
      Error:
      ! `round` must be one of "byte" or "line", not "bytes".
      i Did you mean "byte"?
    Code
      as_round_function(function(x) 1)
    Condition
      Error in `as_round_function()`:
      ! `round` must have the argument `bytes`; it currently has `x`.

