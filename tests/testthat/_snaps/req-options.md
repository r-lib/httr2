# validates inputs

    Code
      request_test() %>% req_timeout("x")
    Condition
      Error in `req_timeout()`:
      ! `seconds` must be a number, not the string "x".
    Code
      request_test() %>% req_timeout(0)
    Condition
      Error in `req_timeout()`:
      ! `seconds` must be >1 ms.

# can request verbose record of request

    Code
      . <- req_perform(req1)
    Output
      -> POST /post HTTP/1.1
      -> Host: http://example.com
      -> Accept: */*
      -> Content-Length: 17
      -> 
      >> This is some text
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
      <<     "Accept": "*/*",
      <<     "Content-Length": "17"
      <<   },
      <<   "json": {},
      <<   "method": "post",
      <<   "path": "/post",
      <<   "origin": "127.0.0.1",
      <<   "url": "<webfakes>post"
      << }

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
      <<     "Host": "http://example.com",
      <<     "Accept": "*/*"
      <<   },
      <<   "json": {},
      <<   "method": "get",
      <<   "path": "/gzip",
      <<   "origin": "127.0.0.1",
      <<   "url": "<webfakes>gzip",
      <<   "gzipped": true
      << }

# req_proxy gives helpful errors

    Code
      req %>% req_proxy(port = "abc")
    Condition
      Error in `req_proxy()`:
      ! `port` must be a whole number or `NULL`, not the string "abc".
    Code
      req %>% req_proxy("abc", auth = "bsc")
    Condition
      Error in `req_proxy()`:
      ! `auth` must be one of "basic", "digest", "gssnegotiate", "ntlm", "digest_ie", or "any", not "bsc".
      i Did you mean "basic"?

