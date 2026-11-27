# checks its inputs

    Code
      req_perform_connection_promise(1)
    Condition
      Error in `req_perform_connection_promise()`:
      ! `req` must be an HTTP request object, not the number 1.
    Code
      req_perform_connection_promise(req, verbosity = "INVALID")
    Condition
      Error in `req_perform_connection_promise()`:
      ! `verbosity` must be 0, 1, 2, or 3.

# close() closes the streaming body

    Code
      resp_stream_raw(resp)
    Condition
      Error in `resp_stream_raw()`:
      ! `resp` has already been closed.

