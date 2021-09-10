# query components must be length 1

    Code
      req <- request("http://example.com/")
      req %>% req_url_query(a = mean)
    Error <rlang_error>
      Query parameters must be length 1 atomic vectors.
      * Problems: a
    Code
      req %>% req_url_query(a = letters)
    Error <rlang_error>
      Query parameters must be length 1 atomic vectors.
      * Problems: a

