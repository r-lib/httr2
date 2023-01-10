# 

    Code
      (expect_error(check_content_type("application/ld+json2", "application/json")))
    Output
      <error/rlang_error>
      Error:
      ! Unexpected content type 'application/ld+json2'
      i Expecting 'application/json' or 'application/<subtype>+json'
    Code
      (expect_error(check_content_type("app/ld+json", "application/json")))
    Output
      <error/rlang_error>
      Error:
      ! Unexpected content type 'app/ld+json'
      i Expecting 'application/json' or 'application/<subtype>+json'

# check_content_type() can consult suffixes

    Code
      (expect_error(check_content_type("application/json", "application/xml")))
    Output
      <error/rlang_error>
      Error:
      ! Unexpected content type 'application/json'
      i Expecting 'application/xml' or 'application/<subtype>+xml'

---

    Code
      (expect_error(check_content_type("application/test+json", "application/xml")))
    Output
      <error/rlang_error>
      Error:
      ! Unexpected content type 'application/test+json'
      i Expecting 'application/xml' or 'application/<subtype>+xml'

---

    Code
      (expect_error(check_content_type("application/xml", c("text/html",
        "application/json"))))
    Output
      <error/rlang_error>
      Error:
      ! Unexpected content type 'application/xml'
      i Expecting one of:
      * 'text/html' or 'text/<subtype>+html'
      * 'application/json' or 'application/<subtype>+json'

---

    Code
      (expect_error(check_content_type("application/xml", "application/xhtml+xml")))
    Output
      <error/rlang_error>
      Error:
      ! Unexpected content type 'application/xml'
      i Expecting 'application/xhtml+xml'

