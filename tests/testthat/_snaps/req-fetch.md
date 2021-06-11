# authorization headers are redacted

    Code
      request("http://example.com") %>% req_auth_basic("user", "password") %>%
        req_user_agent("test") %>% req_dry_run()
    Output
      -> GET / HTTP/1.1
      -> Host: example.com
      -> User-Agent: test
      -> Accept: */*
      -> Accept-Encoding: deflate, gzip
      -> Authorization: <REDACTED>
      -> 

