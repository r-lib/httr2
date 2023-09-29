# req_perform_multi() checks inputs

    Code
      req_perform_multi("a")
    Condition
      Error in `req_perform_multi()`:
      ! `req` must be an HTTP request object, not the string "a".
    Code
      req_perform_multi(request("http://example.com"))
    Condition
      Error in `check_has_multi_policy()`:
      ! `req` doesn't have a multi request policy.
      i You can add pagination via `req_paginate()`.
      i You can create a chunked requests via `req_chunk()`.
    Code
      req_perform_multi(req, max_requests = 0)
    Condition
      Error in `req_perform_multi()`:
      ! `max_requests` must be a whole number larger than or equal to 1 or `NULL`, not the number 0.
    Code
      req_perform_multi(req, progress = -1)
    Condition
      Error in `req_perform_multi()`:
      ! `progress` must be a bool, a string, or a list, not the number -1.

# req_perform_multi() handles error in `parse_resp()`

    Code
      req_perform_multi(req, max_requests = 2)
    Condition
      Error in `parse_resp()`:
      ! error

