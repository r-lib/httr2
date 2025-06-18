# validates inputs

    Code
      req_timeout(request_test(), "x")
    Condition
      Error in `req_timeout()`:
      ! `seconds` must be a number, not the string "x".
    Code
      req_timeout(request_test(), 0)
    Condition
      Error in `req_timeout()`:
      ! `seconds` must be >1 ms.

# req_proxy gives helpful errors

    Code
      req_proxy(req, port = "abc")
    Condition
      Error in `req_proxy()`:
      ! `port` must be a whole number or `NULL`, not the string "abc".
    Code
      req_proxy(req, "abc", auth = "bsc")
    Condition
      Error in `req_proxy()`:
      ! `auth` must be one of "basic", "digest", "gssnegotiate", "ntlm", "digest_ie", or "any", not "bsc".
      i Did you mean "basic"?

