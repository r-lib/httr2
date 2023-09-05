# can check type of response

    Code
      resp_check_content_type(resp1, "application/xml")
    Condition
      Error:
      ! Unexpected content type "application/json".
      * Expecting type "application/xml"
    Code
      resp_check_content_type(resp2, "application/xml")
    Condition
      Error:
      ! Unexpected content type "xxxxx".
      * Expecting type "application/xml"

# useful error even if no content type

    Code
      resp_check_content_type(resp, "application/xml")
    Condition
      Error:
      ! Unexpected content type "NA".
      * Expecting type "application/xml"

# check_content_type() can consult suffixes

    Code
      check_content_type("application/json", "application/xml")
    Condition
      Error:
      ! Unexpected content type "application/json".
      * Expecting type "application/xml"

---

    Code
      check_content_type("application/test+json", "application/xml", "xml")
    Condition
      Error:
      ! Unexpected content type "application/test+json".
      * Expecting type "application/xml" or suffix "xml".

---

    Code
      check_content_type("application/xml", c("text/html", "application/json"))
    Condition
      Error:
      ! Unexpected content type "application/xml".
      * Expecting type "text/html" or "application/json"

