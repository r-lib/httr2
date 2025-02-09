# body is shown

    Code
      req %>% req_body_json(list(x = 1, y = TRUE, z = "c")) %>% req_dry_run()
    Output
      POST / HTTP/1.1
      accept: */*
      content-length: 24
      content-type: application/json
      host: example.com
      
      {"x":1,"y":true,"z":"c"}

---

    Code
      req %>% req_body_raw("Cenário", type = "text/plain") %>% req_dry_run()
    Output
      POST / HTTP/1.1
      accept: */*
      content-length: 8
      content-type: text/plain
      host: example.com
      
      Cenário

---

    Code
      req %>% req_body_raw("Cenário") %>% req_dry_run()
    Output
      POST / HTTP/1.1
      accept: */*
      content-length: 8
      host: example.com
      
      <8 bytes>

# authorization headers are redacted

    Code
      request("http://example.com") %>% req_headers(`Accept-Encoding` = "gzip") %>%
        req_auth_basic("user", "password") %>% req_user_agent("test") %>% req_dry_run()
    Output
      GET / HTTP/1.1
      accept: */*
      accept-encoding: gzip
      authorization: <REDACTED>
      host: example.com
      user-agent: test
      

