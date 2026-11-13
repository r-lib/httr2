# body is shown

    Code
      req_dry_run(req_utf8)
    Output
      POST / HTTP/1.1
      accept: */*
      content-type: text/plain
      
      Cenário

---

    Code
      req_dry_run(req_json)
    Output
      POST / HTTP/1.1
      accept: */*
      content-type: application/json
      
      {
        "x": 1,
        "y": true
      }

---

    Code
      req_dry_run(req_json, pretty_json = FALSE)
    Output
      POST / HTTP/1.1
      accept: */*
      content-type: application/json
      
      {"x":1,"y":true}

---

    Code
      req_dry_run(req_binary)
    Output
      POST / HTTP/1.1
      accept: */*
      
      <8 bytes>

# authorization headers are redacted

    Code
      out <- req_dry_run(req)
    Output
      GET / HTTP/1.1
      accept: */*
      authorization: <REDACTED>
      

---

    Code
      out <- req_dry_run(req, redact_headers = FALSE)
    Output
      GET / HTTP/1.1
      accept: */*
      authorization: Basic dXNlcjpwYXNzd29yZA==
      

# query strings are shown (#868)

    Code
      out <- req_dry_run(req)
    Output
      GET /example-path?a=1&b=2&c=3 HTTP/1.1
      accept: */*
      

