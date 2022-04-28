# query components must be length 1

    Code
      req <- request("http://example.com/")
      req %>% req_url_query(a = mean)
    Condition
      Error in `query_build()`:
      ! Query parameters must be length 1 atomic vectors.
      * Problems: a
    Code
      req %>% req_url_query(a = letters)
    Condition
      Error in `query_build()`:
      ! Query parameters must be length 1 atomic vectors.
      * Problems: a

