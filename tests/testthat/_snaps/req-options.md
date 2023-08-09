# can request verbose record of request

    -> POST /post HTTP/1.1
    -> Host: http://example.com
    -> User-Agent: verbose
    -> Accept: */*
    -> Accept-Encoding: gzip
    -> Content-Length: 17
    -> 
    >> This is some text

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

