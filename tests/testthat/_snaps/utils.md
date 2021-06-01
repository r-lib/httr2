# modify list adds, removes, and overrides

    Code
      modify_list(x, a = 1, 2)
    Error <rlang_error>
      All components of ... must be named

# can check arg types

    Code
      check_string(1, "x")
    Error <rlang_error>
      x must be a string
    Code
      check_number("2", "x")
    Error <rlang_error>
      x must be a number
    Code
      check_number(NA_real_, "x")
    Error <rlang_error>
      x must be a number

