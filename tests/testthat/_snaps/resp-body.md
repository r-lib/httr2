# empty body generates error

    Code
      request_test("HEAD /get") %>% req_perform() %>% resp_body_raw()
    Condition
      Error in `resp_body_raw()`:
      ! Can not retrieve empty body

# content types are checked

    Code
      request_test("/xml") %>% req_perform() %>% resp_body_json()
    Condition
      Error in `check_content_type()`:
      ! Unexpected content type 'application/xml'
      Expecting 'application/json'
      Or suffix '+json'
      i Override check with `check_type = FALSE`
    Code
      request_test("/json") %>% req_perform() %>% resp_body_xml()
    Condition
      Error in `check_content_type()`:
      ! Unexpected content type 'application/json'
      Expecting one of 'application/xml', 'text/xml'
      Or suffix '+xml'
      i Override check with `check_type = FALSE`

