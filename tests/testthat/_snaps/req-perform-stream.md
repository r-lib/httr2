# req_stream() is deprecated

    Code
      resp <- req_stream(req, identity, buffer_kb = 32)
    Condition
      Warning:
      `req_stream()` was deprecated in httr2 1.0.0.
      i Please use `req_perform_stream()` instead.

# can't read from a closed connection

    Code
      resp_stream_raw(resp, 1)
    Condition
      Error in `resp_stream_raw()`:
      ! `resp` has already been closed.

# resp_stream_sse() requires a text connection

    Code
      resp_stream_sse(resp)
    Condition
      Error in `resp_stream_sse()`:
      ! `resp` must have a text mode connection.
      i Use `mode = "text"` when calling `req_perform_connection()`.

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

