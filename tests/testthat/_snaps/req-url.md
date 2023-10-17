# query components must be length 1

    Code
      req %>% req_url_query(a = mean)
    Condition
      Error in `req_url_query()`:
      ! All elements of `...` must be either an atomic vector or NULL.

