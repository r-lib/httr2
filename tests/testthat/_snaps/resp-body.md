# content types are checked

    Code
      req_test("/xml") %>% req_fetch() %>% resp_body_json()
    Error <rlang_error>
      Declared content type is not 'application/json'
      i Override check with `check_type = FALSE`
    Code
      req_test("/json") %>% req_fetch() %>% resp_body_xml()
    Error <rlang_error>
      Declared content type is not one of 'application/xml', 'text/xml'
      i Override check with `check_type = FALSE`

