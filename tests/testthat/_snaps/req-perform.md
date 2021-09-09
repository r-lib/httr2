# req_dry_run() shows body

    Code
      request("http://example.com") %>% req_headers(`Accept-Encoding` = "gzip") %>%
        req_body_json(list(x = 1, y = TRUE, z = "c")) %>% req_user_agent("test") %>%
        req_dry_run()
    Output
      POST / HTTP/1.1
      Host: example.com
      User-Agent: test
      Accept: */*
      Accept-Encoding: gzip
      Content-Type: application/json
      Content-Length: 24
      
      {"x":1,"y":true,"z":"c"}

# authorization headers are redacted

    Code
      request("http://example.com") %>% req_headers(`Accept-Encoding` = "gzip") %>%
        req_auth_basic("user", "password") %>% req_user_agent("test") %>% req_dry_run()
    Output
      GET / HTTP/1.1
      Host: example.com
      User-Agent: test
      Accept: */*
      Accept-Encoding: gzip
      Authorization: <REDACTED>
      

