# request and paths must match

    Code
      req_perform_multi(req, letters)
    Condition
      Error in `req_perform_multi()`:
      ! If supplied, `paths` must be the same length as `req`.

# multi_req_perform is deprecated

    Code
      multi_req_perform(list())
    Condition
      Warning:
      `multi_req_perform()` was deprecated in httr2 0.3.0.
      i Please use `req_perform_multi()` instead.
    Output
      list()

