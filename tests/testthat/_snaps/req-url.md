# query params don't accept secrets

    Code
      req_url_query(req, a = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))
    Condition
      Error in `url_modify_query()`:
      ! Query value `a` must be a length-1 atomic vector, not a <httr2_obfuscated> object.
    Code
      req_url_query(req, a = function() "x")
    Condition
      Error in `url_modify_query()`:
      ! All elements of `...` must be either an atomic vector or NULL.
    Code
      url_modify_query("http://example.com/", a = obfuscated(
        "ZdYJeG8zwISodg0nu4UxBhs"))
    Condition
      Error in `url_modify_query()`:
      ! Query value `a` must be a length-1 atomic vector, not a <httr2_obfuscated> object.

# can control space handling

    Code
      req_url_query(req, a = " ", .space = "bar")
    Condition
      Error in `multi_dots()`:
      ! `.space` must be one of "percent" or "form", not "bar".

# can handle multi query params

    Code
      req_url_query_multi("error")
    Condition
      Error in `url_modify_query()`:
      ! All vector elements of `...` must be length 1.
      i Use `.multi` to choose a strategy for handling vectors.

# errors are forwarded correctly

    Code
      req_url_query(req, 1)
    Condition
      Error in `url_modify_query()`:
      ! All components of `...` must be named.
    Code
      req_url_query(req, a = I(1))
    Condition
      Error in `url_modify_query()`:
      ! Escaped query value `a` must be a single string, not the number 1.
    Code
      req_url_query(req, a = 1:2)
    Condition
      Error in `url_modify_query()`:
      ! All vector elements of `...` must be length 1.
      i Use `.multi` to choose a strategy for handling vectors.
    Code
      req_url_query(req, a = mean)
    Condition
      Error in `url_modify_query()`:
      ! All elements of `...` must be either an atomic vector or NULL.

