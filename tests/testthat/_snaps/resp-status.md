# get some useful output from WWW-Authenticate header

    HTTP 401 Unauthorized.
    * OAuth error: invalid_token - The access token expired
    * realm: example

---

    HTTP 403 Forbidden.
    * OAuth error: insufficient_scope
    * realm: https://accounts.google.com/
    * scope: https://www.googleapis.com/auth/iam https://www.googleapis.com/auth/cloud-platform

# WWW-Authenticate header without extra fields has no empty bullet

    Code
      resp_check_status(resp)
    Condition
      Error:
      ! HTTP 401 Unauthorized.
      * OAuth error

---

    Code
      resp_check_status(resp)
    Condition
      Error:
      ! HTTP 401 Unauthorized.
      * OAuth error: invalid_token

