# bad inputs get clear error

    Code
      req_headers(req, fun = mean)
    Condition
      Error in `req_headers()`:
      ! All elements of `...` must be either an atomic vector or NULL.
    Code
      req_headers(req, 1)
    Condition
      Error in `req_headers()`:
      ! All components of `...` must be named.

# is case insensitive

    Code
      req
    Message
      <httr2_request>
      GET http://example.com
      Headers:
      * a: <REDACTED>
      Body: empty

# checks input types

    Code
      req_headers(req, a = 1L, b = 2L, .redact = 1L)
    Condition
      Error in `req_headers()`:
      ! `.redact` must be a character vector or `NULL`, not the number 1.

