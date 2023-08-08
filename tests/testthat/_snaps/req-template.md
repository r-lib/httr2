# generates useful errors

    Code
      req_template(req, 1)
    Condition
      Error in `req_template()`:
      ! `template` must be a single string, not the number 1.
    Code
      req_template(req, "x", 1)
    Condition
      Error in `req_template()`:
      ! All elements of ... must be named
    Code
      req_template(req, "A B C")
    Condition
      Error in `req_template()`:
      ! Can't parse template `template`
      i Should have form like 'GET /a/b/c' or 'a/b/c/'

# template produces useful errors

    Code
      template_process(":b")
    Condition
      Error in `FUN()`:
      ! Can't find template variable 'b'
    Code
      template_process(":b", list(b = sum))
    Condition
      Error in `FUN()`:
      ! Template variable 'b' is not a simple scalar value

