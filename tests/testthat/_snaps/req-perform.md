# curl errors become errors

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! Failed to perform HTTP request.
      Caused by error in `curl_fetch()`:
      ! Failed to connect

# http errors become errors

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! HTTP 404 Not Found.

---

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! HTTP 429 Too Many Requests.

---

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! HTTP 599.

# checks input types

    Code
      req_perform(req, path = 1)
    Condition
      Error in `req_perform()`:
      ! `path` must be a single string or `NULL`, not the number 1.
    Code
      req_perform(req, verbosity = 1.5)
    Condition
      Error in `req_perform()`:
      ! `verbosity` must 0, 1, 2, or 3.
    Code
      req_perform(req, mock = 7)
    Condition
      Error in `req_perform()`:
      ! `mock` must be function, list, or NULL, not the number 7.

