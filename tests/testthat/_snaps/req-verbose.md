# can request verbose record of request

    Code
      . <- req_perform(verbose_resp)
    Output
      <- HTTP/1.1 200 OK
      <- Connection: close
      <- Content-Type: application/json
      <- 
      << {
      <<   "x": 1
      << }

---

    Code
      . <- req_perform(verbose_req)
    Output
      -> POST /test HTTP/1.1
      -> Host: http://example.com
      -> Content-Length: 17
      -> 
      >> This is some text

# can display compressed bodies

    Code
      . <- req_perform(req)
    Output
      <- HTTP/1.1 200 OK
      <- Content-Type: application/json
      <- Content-Encoding: gzip
      <- 
      << {
      <<   "args": {
      << 
      <<   },
      <<   "data": {
      << 
      <<   },
      <<   "files": {
      << 
      <<   },
      <<   "form": {
      << 
      <<   },
      <<   "headers": {
      <<     "Host": "http://example.com"
      <<   },
      <<   "json": {
      << 
      <<   },
      <<   "method": "get",
      <<   "path": "/gzip",
      <<   "origin": "127.0.0.1",
      <<   "url": "<webfakes>/gzip",
      <<   "gzipped": true
      << }

# json is automatically prettified

    Code
      . <- req_perform(req)
    Output
      << {
      <<   "foo": "bar",
      <<   "baz": [
      <<     1,
      <<     2,
      <<     3
      <<   ]
      << }

---

    Code
      . <- req_perform(req)
    Output
      << {"foo":"bar","baz":[1,2,3]}

# verbose_enum checks range

    Code
      verbose_enum(7)
    Condition
      Warning:
      Unknown verbosity level 7

