# modify list adds, removes, and overrides

    Code
      modify_list(x, a = 1, 2)
    Condition
      Error in `modify_list()`:
      ! All components of ... must be named

# can check arg types

    Code
      check_number("2", "x")
    Condition
      Error in `check_number()`:
      ! x must be a number
    Code
      check_number(NA_real_, "x")
    Condition
      Error in `check_number()`:
      ! x must be a number

