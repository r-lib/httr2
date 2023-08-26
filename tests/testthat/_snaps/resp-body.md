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
      ! Unexpected content type "application/xml"
      * Expecting "application/json", or suffix "json"
    Code
      request_test("/json") %>% req_perform() %>% resp_body_xml()
    Condition
      Error in `resp_body_xml()`:
      ! Unexpected content type "application/json"
      * Expecting "application/xml" or "text/xml", or suffix "xml"

