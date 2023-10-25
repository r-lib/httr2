# iterate_with_offset checks inputs

    Code
      iterate_with_offset(1)
    Condition
      Error in `iterate_with_offset()`:
      ! `param_name` must be a single string, not the number 1.
    Code
      iterate_with_offset("x", "x")
    Condition
      Error in `iterate_with_offset()`:
      ! `start` must be a whole number, not the string "x".
    Code
      iterate_with_offset("x", offset = 0)
    Condition
      Error in `iterate_with_offset()`:
      ! `offset` must be a whole number larger than or equal to 1, not the number 0.
    Code
      iterate_with_offset("x", offset = "x")
    Condition
      Error in `iterate_with_offset()`:
      ! `offset` must be a whole number, not the string "x".
    Code
      iterate_with_offset("x", resp_complete = function(x, y) x + y)
    Condition
      Error in `iterate_with_offset()`:
      ! `resp_complete` must have the argument `resp`; it currently has `x` and `y`.

# iterate_with_cursor

    Code
      iterate_with_cursor(1)
    Condition
      Error in `iterate_with_cursor()`:
      ! `param_name` must be a single string, not the number 1.
    Code
      iterate_with_cursor("x", function(x, y) x + y)
    Condition
      Error in `iterate_with_cursor()`:
      ! `resp_param_value` must have the argument `resp`; it currently has `x` and `y`.

# iterate_with_link_url checks its inputs

    Code
      iterate_with_link_url(rel = 1)
    Condition
      Error in `iterate_with_link_url()`:
      ! `rel` must be a single string, not the number 1.

