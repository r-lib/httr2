# can't change body type

    Code
      req_body_json(req, list(x = 1))
    Condition
      Error in `req_body_json()`:
      ! Can't change body type from raw to json.
      i You must use only one type of `req_body_*()` per request.

# can't send anything else

    Code
      req_body_raw(req, 1)
    Condition
      Error in `req_body_raw()`:
      ! `body` must be a raw vector or string.

# errors on invalid input

    Code
      req_body_file(request_test(), 1)
    Condition
      Error in `req_body_file()`:
      ! `path` must be a single string, not the number 1.
    Code
      req_body_file(request_test(), "doesntexist")
    Condition
      Error in `req_body_file()`:
      ! Can't find file 'doesntexist'.
    Code
      req_body_file(request_test(), ".")
    Condition
      Error in `req_body_file()`:
      ! `path` must be a file, not a directory.

# non-json type errors

    Code
      req_body_json(request_test(), mtcars, type = "application/xml")
    Condition
      Error in `req_body_json()`:
      ! Unexpected content type "application/xml".
      * Expecting type "application/json" or suffix "json".

# can't modify non-json data

    Code
      req_body_json_modify(req, a = 1)
    Condition
      Error in `req_body_json_modify()`:
      ! Can only be used after `req_body_json()`.

# can send named elements as multipart

    Code
      cat(req_get_body(req))
    Output
      ---{id}
      Content-Disposition: form-data; name="a"
      
      1
      ---{id}
      Content-Disposition: form-data; name="b"
      
      2
      ---{id}

