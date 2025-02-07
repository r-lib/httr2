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

