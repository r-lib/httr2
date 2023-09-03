# as_callback validates inputs

    Code
      as_callback(function(x) 2, 2, "foo")
    Condition
      Error:
      ! Callback `name()` must have 2 arguments

