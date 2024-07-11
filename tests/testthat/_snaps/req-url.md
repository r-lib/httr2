# can handle multi query params

    Code
      req_url_query_multi("error")
    Condition
      Error in `req_url_query()`:
      ! All vector elements of `...` must be length 1.
      i Use `.multi` to choose a strategy for handling vectors.

# errors are forwarded correctly

    Code
      req %>% req_url_query(1)
    Condition
      Error in `req_url_query()`:
      ! All components of `...` must be named.
    Code
      req %>% req_url_query(a = I(1))
    Condition
      Error in `req_url_query()`:
      ! Escaped query value `a` must be a single string, not the number 1.
    Code
      req %>% req_url_query(a = 1:2)
    Condition
      Error in `req_url_query()`:
      ! All vector elements of `...` must be length 1.
      i Use `.multi` to choose a strategy for handling vectors.
    Code
      req %>% req_url_query(a = mean)
    Condition
      Error in `req_url_query()`:
      ! All elements of `...` must be either an atomic vector or NULL.

