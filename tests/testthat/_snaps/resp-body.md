# empty body generates error

    Code
      request_test("HEAD /get") %>% req_perform() %>% resp_body_raw()
    Error <rlang_error>
      Can not retrieve empty body

# content types are checked

    Code
      request_test("/xml") %>% req_perform() %>% resp_body_json()
    Error <rlang_error>
      Declared content type is not 'application/json'
      i Override check with `check_type = FALSE`
    Code
      request_test("/json") %>% req_perform() %>% resp_body_xml()
    Error <rlang_error>
      Declared content type is not one of 'application/xml', 'text/xml'
      i Override check with `check_type = FALSE`

