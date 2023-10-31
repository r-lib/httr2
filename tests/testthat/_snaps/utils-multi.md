# checks its inputs

    Code
      multi_dots(1)
    Condition
      Error:
      ! All components of `...` must be named.
    Code
      multi_dots(x = I(1))
    Condition
      Error:
      ! Escaped query value must be a single string, not the number 1.
    Code
      multi_dots(x = 1:2)
    Condition
      Error:
      ! All vector elements of `...` must be length 1.
      i Use `.multi` to choose a strategy for handling vectors.
    Code
      multi_dots(x = mean)
    Condition
      Error:
      ! All elements of `...` must be either an atomic vector or NULL.

