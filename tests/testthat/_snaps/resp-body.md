# empty body generates error

    Code
      resp_body_raw(resp1)
    Condition
      Error in `resp_body_raw()`:
      ! Can not retrieve empty body

---

    Code
      resp_body_raw(resp2)
    Condition
      Error in `resp_body_raw()`:
      ! Can not retrieve empty body

# content types are checked

    Code
      request_test("/xml") %>% req_perform() %>% resp_body_json()
    Condition
      Error in `resp_body_json()`:
      ! Unexpected content type 'application/xml'
      i Expecting 'application/json' or 'application/<subtype>+json'
      i Override check with `check_type = FALSE`
    Code
      request_test("/json") %>% req_perform() %>% resp_body_xml()
    Condition
      Error in `resp_body_xml()`:
      ! Unexpected content type 'application/json'
      i Expecting one of:
      * 'application/xml' or 'application/<subtype>+xml'
      * 'text/xml' or 'text/<subtype>+xml'
      i Override check with `check_type = FALSE`

