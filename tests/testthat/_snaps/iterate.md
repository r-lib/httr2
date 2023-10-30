# user temination still returns data

    Code
      resps <- req_perform_iterative(req, next_req = next_req)
    Message
      ! Terminating iteration; returning 1 response.

# checks its inputs

    Code
      req_perform_iterative(1)
    Condition
      Error in `req_perform_iterative()`:
      ! `req` must be an HTTP request object, not the number 1.
    Code
      req_perform_iterative(req, function(x, y) x + y)
    Condition
      Error in `req_perform_iterative()`:
      ! `next_req` must have the arguments `resp` and `req`; it currently has `x` and `y`.
    Code
      req_perform_iterative(req, function(resp, req) { }, path = 1)
    Condition
      Error in `req_perform_iterative()`:
      ! `path` must be a single string or `NULL`, not the number 1.
    Code
      req_perform_iterative(req, function(resp, req) { }, max_reqs = -1)
    Condition
      Error in `req_perform_iterative()`:
      ! `max_reqs` must be a whole number larger than or equal to 1, not the number -1.
    Code
      req_perform_iterative(req, function(resp, req) { }, progress = -1)
    Condition
      Error in `req_perform_iterative()`:
      ! `progress` must be a bool, a string, or a list, not the number -1.

