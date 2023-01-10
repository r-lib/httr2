# failing callback still generates useful body

    Failed to parse error body with method defined in req_error()
    Caused by error:
    ! This is an error!

---

    Code
      req <- request("https://httpbin.org/status/404")
      req <- req %>% req_error(body = ~ resp_body_json(.x)$error)
      req %>% req_perform()
    Condition
      Error in `req_perform()`:
      ! Failed to parse error body with method defined in req_error()
      Caused by error in `resp_body_json()`:
      ! Unexpected content type 'text/html'
      i Expecting 'application/json' or 'application/<subtype>+json'
      i Override check with `check_type = FALSE`

