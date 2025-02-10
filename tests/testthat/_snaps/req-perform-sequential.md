# checks its inputs

    Code
      req_perform_sequential(req)
    Condition
      Error in `req_perform_sequential()`:
      ! `reqs` must be a list, not a <httr2_request> object.
    Code
      req_perform_sequential(list(req), letters)
    Condition
      Error in `req_perform_sequential()`:
      ! If supplied, `paths` must be the same length as `req`.

