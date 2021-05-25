# generates useful errors

    Code
      req_template(req, 1)
    Error <rlang_error>
      `template` must be a string
    Code
      req_template(req, "x", 1)
    Error <rlang_error>
      All elements of ... must be named
    Code
      req_template(req, "A B C")
    Error <rlang_error>
      Can't parse template `template`
      i Should have form like 'GET /a/b/c' or 'a/b/c/'

# template produces useful errors

    Code
      template_process(":b")
    Error <rlang_error>
      Can't find template variable 'b'
    Code
      template_process(":b", list(b = sum))
    Error <rlang_error>
      Template variable 'b' is not a simple scalar value

