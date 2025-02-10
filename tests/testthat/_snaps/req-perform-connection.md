# validates inputs

    Code
      req_perform_connection(1)
    Condition
      Error in `req_perform_connection()`:
      ! `req` must be an HTTP request object, not the number 1.
    Code
      req_perform_connection(request_test(), 1)
    Condition
      Error in `req_perform_connection()`:
      ! `blocking` must be `TRUE` or `FALSE`, not the number 1.

# curl errors become errors

    Code
      req_perform_connection(req)
    Condition
      Error in `req_perform_connection()`:
      ! Failed to perform HTTP request.
      Caused by error in `open.connection()`:
      ! cannot open the connection

