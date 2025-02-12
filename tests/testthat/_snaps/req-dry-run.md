# body is shown

    Code
      req_dry_run(req_utf8)
    Output
      POST / HTTP/1.1
      accept: */*
      content-length: 8
      content-type: text/plain
      user-agent: <httr2 user agent>
      
      Cenário

---

    Code
      req_dry_run(req_json)
    Output
      POST / HTTP/1.1
      accept: */*
      content-length: 16
      content-type: application/json
      user-agent: <httr2 user agent>
      
      {"x":1,"y":true}

---

    Code
      req_dry_run(req_json, pretty_json = FALSE)
    Output
      POST / HTTP/1.1
      accept: */*
      content-length: 16
      content-type: application/json
      user-agent: <httr2 user agent>
      
      {"x":1,"y":true}

---

    Code
      req_dry_run(req_binary)
    Output
      POST / HTTP/1.1
      accept: */*
      content-length: 8
      user-agent: <httr2 user agent>
      
      <8 bytes>

# authorization headers are redacted

    Code
      req_dry_run(req)
    Output
      GET / HTTP/1.1
      accept: */*
      authorization: <REDACTED>
      user-agent: <httr2 user agent>
      

