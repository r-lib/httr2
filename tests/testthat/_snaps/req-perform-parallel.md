# request and paths must match

    Code
      req_perform_parallel(req, letters)
    Condition
      Error in `req_perform_parallel()`:
      ! If supplied, `paths` must be the same length as `req`.

# req_perform_parallel respects http_error() body message

    Code
      req_perform_parallel(reqs)
    Condition
      Error in `req_perform_parallel()`:
      ! HTTP 404 Not Found.
      * hello

