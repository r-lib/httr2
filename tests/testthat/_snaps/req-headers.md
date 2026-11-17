# bad inputs get clear error

    Code
      req_headers(req, fun = mtcars)
    Condition
      Error in `req_headers()`:
      ! All elements of `...` must be either an atomic vector, a secret, or NULL.
    Code
      req_headers(req, 1)
    Condition
      Error in `req_headers()`:
      ! All components of `...` must be named.

# is case insensitive

    Code
      req
    Output
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

# secret headers display redacted

    Code
      req
    Output
      <httr2_request>
      GET http://example.com
      Headers:
      * a: <REDACTED (env: SECRET_HEADER_TEST)>
      * b: <REDACTED>
      * c: <REDACTED (on-demand)>
      * d: <REDACTED (obfuscated)>
      Body: empty

