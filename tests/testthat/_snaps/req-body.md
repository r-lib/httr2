# errors if file doesn't exist

    Code
      req_body_file(request_test(), "doesntexist", type = "text/plain")
    Condition
      Error in `req_body_file()`:
      ! `path` ('doesntexist') does not exist.

# non-json type errors

    Code
      req_body_json(request_test(), mtcars, type = "application/xml")
    Condition
      Error in `req_body_json()`:
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

