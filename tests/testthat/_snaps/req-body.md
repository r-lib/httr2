# can use custom json type

    Code
      (expect_error(req %>% req_headers(`Content-Type` = "application/ld+json2") %>%
        req_body_apply()))
    Output
      <error/rlang_error>
      Error in `req_body_apply()`:
      ! Unexpected content type 'application/ld+json2'
      * Expecting 'application/json'
    Code
      (expect_error(req %>% req_headers(`Content-Type` = "app/ld+json") %>%
        req_body_apply()))
    Output
      <error/rlang_error>
      Error in `req_body_apply()`:
      ! Unexpected content type 'app/ld+json'
      * Expecting 'application/json'

# req_body_form() and req_body_multipart() accept list() with warning

    Code
      req1 <- req %>% req_body_form(list(x = "x"))
    Condition
      Warning in `req_body_form()`:
      This function longers takes a list, instead supply named arguments in ...
    Code
      req2 <- req %>% req_body_multipart(list(x = "x"))
    Condition
      Warning in `req_body_multipart()`:
      This function longers takes a list, instead supply named arguments in ...

