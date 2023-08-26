# non-json type errors

    Code
      req_perform(req)
    Condition
      Error in `req_body_apply()`:
      ! Unexpected content type "application/xml"
      * Expecting type "application/json", or suffix "json"

# req_body_form() and req_body_multipart() accept list() with warning

    Code
      req1 <- req %>% req_body_form(list(x = "x"))
    Condition
      Warning in `req_body_form()`:
      This function no longer takes a list, instead supply named arguments in ...
    Code
      req2 <- req %>% req_body_multipart(list(x = "x"))
    Condition
      Warning in `req_body_multipart()`:
      This function no longer takes a list, instead supply named arguments in ...

