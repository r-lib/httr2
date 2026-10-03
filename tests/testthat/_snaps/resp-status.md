# get some useful output from WWW-Authenticate header

    HTTP 401 Unauthorized.
    * OAuth error: invalid_token - The access token expired
    * realm: example

---

    HTTP 403 Forbidden.
    * OAuth error: insufficient_scope
    * realm: https://accounts.google.com/
    * scope: https://www.googleapis.com/auth/iam https://www.googleapis.com/auth/cloud-platform

# resp_check_status() includes info in error message

    Code
      resp_check_status(resp, info = c("Extra context.", i = "A hint."))
    Condition
      Error:
      ! HTTP 404 Not Found.
      Extra context.
      i A hint.

