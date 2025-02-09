# can request verbose record of request

    Code
      . <- req_perform(verbose_resp)
    Output
      <- HTTP/1.1 200 OK
      <- Content-Type: application/json
      <- 
      << {
      <<   "args": {},
      <<   "data": {},
      <<   "files": {},
      <<   "form": {},
      <<   "headers": {
      <<     "Host": "http://example.com",
      <<     "Content-Length": "17"
      <<   },
      <<   "json": {},
      <<   "method": "post",
      <<   "path": "/post",
      <<   "origin": "127.0.0.1",
      <<   "url": "<webfakes>/post"
      << }

---

    Code
      . <- req_perform(verbose_req)
    Output
      -> POST /post HTTP/1.1
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
      <<   "args": {},
      <<   "data": {},
      <<   "files": {},
      <<   "form": {},
      <<   "headers": {
      <<     "Host": "http://example.com"
      <<   },
      <<   "json": {},
      <<   "method": "get",
      <<   "path": "/gzip",
      <<   "origin": "127.0.0.1",
      <<   "url": "<webfakes>/gzip",
      <<   "gzipped": true
      << }

