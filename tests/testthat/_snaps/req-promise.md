# req_perform_promise uses the default loop

    Code
      p4 <- req_perform_promise(request_test("/get"))
    Condition
      Error in `req_perform_promise()`:
      ! Must supply `pool` when calling `later::with_temp_loop()`
      i Do you need `pool = curl::new_pool()`?

