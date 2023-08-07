# can request verbose record of request

    -> POST /post HTTP/1.1
    -> Host: http://example.com
    -> User-Agent: verbose
    -> Accept: */*
    -> Accept-Encoding: gzip
    -> Content-Length: 17
    -> 
    >> 17 bytes of binary data

# req_proxy gives helpful errors

    Code
      req %>% req_proxy(port = "abc")
    Condition
      Error in `req_proxy()`:
      ! `port` must be a number
    Code
      req %>% req_proxy("abc", auth = "bsc")
    Condition
      Error in `req_proxy()`:
      ! `auth` must be one of "basic", "digest", "gssnegotiate", "ntlm", "digest_ie", or "any", not "bsc".
      i Did you mean "basic"?

