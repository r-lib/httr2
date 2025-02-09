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

