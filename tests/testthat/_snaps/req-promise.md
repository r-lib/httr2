# checks its inputs

    Code
      req_perform_promise(1)
    Condition
      Error in `req_perform_promise()`:
      ! `req` must be an HTTP request object, not the number 1.
    Code
      req_perform_promise(req, path = 1)
    Condition
      Error in `req_perform_promise()`:
      ! `path` must be a single string or `NULL`, not the number 1.
    Code
      req_perform_promise(req, pool = "INVALID")
    Condition
      Error in `req_perform_promise()`:
      ! `pool` must be a {curl} pool or `NULL`, not the string "INVALID".
    Code
      req_perform_promise(req, verbosity = "INVALID")
    Condition
      Error in `req_perform_promise()`:
      ! `verbosity` must be 0, 1, 2, or 3.

# pool poller fails informatively when polling fails

    Code
      later::run_now()
    Condition
      Error in `self$poll()`:
      ! Background request polling stopped after an unexpected error.
      i Pending promises may not resolve until a new request is submitted to the same pool.
      Caused by error in `curl_multi_run()`:
      ! Simulated poll failure

# correctly prepares request

    Code
      . <- extract_promise(req_perform_promise(req, verbosity = 1))
    Output
      -> GET /get HTTP/1.1
      -> Host: <variable>
      -> User-Agent: <variable>
      -> Accept: */*
      -> Accept-Encoding: <variable>
      -> 
      <- HTTP/1.1 200 OK
      <- Date: <variable>
      <- Content-Type: application/json
      <- Content-Length: <variable>
      <- ETag: <variable>
      <- 

# req_perform_promise uses the default loop

    Code
      p4 <- req_perform_promise(request_test("/get"))
    Condition
      Error in `req_perform_promise()`:
      ! Must supply `pool` when calling `later::with_temp_loop()`.
      i Do you need `pool = curl::new_pool()`?

