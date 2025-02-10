# body is shown

    Code
      req_dry_run(req_utf8)
    Output
      POST / HTTP/1.1
      content-length: 8
      content-type: text/plain
      host: example.com
      
      Cenário

---

    Code
      req_dry_run(req_json)
    Output
      POST / HTTP/1.1
      content-length: 16
      content-type: application/json
      host: example.com
      
      {"x":1,"y":true}

---

    Code
      req_dry_run(req_binary)
    Output
      POST / HTTP/1.1
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
      

