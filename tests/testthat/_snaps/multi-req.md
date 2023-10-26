# request and paths must match

    Code
      req_perform_parallel(req, letters)
    Condition
      Error in `req_perform_parallel()`:
      ! If supplied, `paths` must be the same length as `req`.

# multi_req_perform is deprecated

    Code
      multi_req_perform(list())
    Condition
      Warning:
      `multi_req_perform()` was deprecated in httr2 1.0.0.
      i Please use `req_perform_parallel()` instead.
    Output
      list()

