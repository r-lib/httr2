# useful message if `after` wrong

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! The `after` callback to `req_retry()` must return a single number or NA, not a <httr2_response> object.

# validates its inputs

    Code
      req_retry(req, max_tries = 1)
    Condition
      Error in `req_retry()`:
      ! `max_tries` must be a whole number larger than or equal to 2 or `NULL`, not the number 1.
    Code
      req_retry(req, max_seconds = "x")
    Condition
      Error in `req_retry()`:
      ! `max_seconds` must be a whole number or `NULL`, not the string "x".
    Code
      req_retry(req, retry_on_failure = "x")
    Condition
      Error in `req_retry()`:
      ! `retry_on_failure` must be `TRUE` or `FALSE`, not the string "x".

