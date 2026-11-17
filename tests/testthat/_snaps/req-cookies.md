# can read/write cookies

    Code
      readLines(cookie_path)[-(1:4)]
    Output
      [1] "127.0.0.1\tFALSE\t/\tFALSE\t0\tz\tc" "127.0.0.1\tFALSE\t/\tFALSE\t0\tx\ta"
      [3] "127.0.0.1\tFALSE\t/\tFALSE\t0\ty\tb"

# cookies don't accept secrets

    Code
      req_cookies_set(req, a = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))
    Condition
      Error in `req_cookies_set()`:
      ! Query value `a` must be a length-1 atomic vector, not a <httr2_obfuscated> object.
    Code
      req_cookies_set(req, a = function() "x")
    Condition
      Error in `req_cookies_set()`:
      ! Query value `a` must be a length-1 atomic vector, not a function.

