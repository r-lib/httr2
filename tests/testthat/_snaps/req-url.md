# can handle multi query params

    Code
      req_url_query_multi("error")
    Condition
      Error in `req_url_query()`:
      ! All vector elements of `...` must be length 1.
      i Use `multi` to choose a strategy for handling.

# query components must be length 1

    Code
      req %>% req_url_query(a = mean)
    Condition
      Error in `req_url_query()`:
      ! All elements of `...` must be either an atomic vector or NULL.

