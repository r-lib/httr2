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
      Caused by error in `check_content_type()`:
      ! Unexpected content type 'text/html'
      Expecting 'application/json'
      Or suffix '+json'
      i Override check with `check_type = FALSE`

