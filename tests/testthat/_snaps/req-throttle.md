# throttling affects request performance

    Code
      time <- system.time(req_perform(req))[[3]]
    Message
      > Waiting 0.15s for throttling delay

# req_throttle checks its inputs

    Code
      req_throttle(request_test(), capacity = "x")
    Condition
      Error in `req_throttle()`:
      ! `capacity` must be a numeric vector, not the string "x".
    Code
      req_throttle(request_test(), capacity = -1)
    Condition
      Error in `req_throttle()`:
      ! Every element of `capacity` must be 0 or greater.
    Code
      req_throttle(request_test(), capacity = 1.5)
    Condition
      Error in `req_throttle()`:
      ! Every element of `capacity` must be a whole number.
    Code
      req_throttle(request_test(), capacity = c(1, 2), fill_time_s = c(1, 2, 3))
    Condition
      Error in `req_throttle()`:
      ! Can't recycle `capacity` (size 2) to match `fill_time_s` (size 3).

