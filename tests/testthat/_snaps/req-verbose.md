# can request verbose record of request

    Code
      . <- req_perform(req1)
    Output
      -> POST /post HTTP/1.1
      -> Host: http://example.com
      -> Content-Length: 17
      -> 
      --start verbose_message--
      >> This is some text
      --end verbose_message--
      <- HTTP/1.1 200 OK
      <- Content-Type: application/json
      <- 
      --start show_body--
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
      --end show_body--

# can display compressed bodies

    Code
      . <- req_perform(req)
    Output
      <- HTTP/1.1 200 OK
      <- Content-Type: application/json
      <- Content-Encoding: gzip
      <- 
      --start show_body--
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
      --end show_body--

