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

# multi_req_perform is deprecated

    Code
      multi_req_perform(list())
    Condition
      Warning:
      `multi_req_perform()` was deprecated in httr2 1.0.0.
      i Please use `req_perform_parallel()` instead.
    Output
      list()

# pool argument is deprecated

    Code
      . <- req_perform_parallel(list(), pool = curl::new_pool())
    Condition
      Warning:
      The `pool` argument of `req_perform_parallel()` is deprecated as of httr2 1.1.0.

