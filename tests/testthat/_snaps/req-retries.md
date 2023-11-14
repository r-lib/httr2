# useful message if `after` wrong

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! The `after` callback to `req_retry()` must return a single number or NA, not a <httr2_response> object.

