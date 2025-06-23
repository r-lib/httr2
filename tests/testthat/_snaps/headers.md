# as_headers errors on invalid types

    Code
      as_headers(1)
    Condition
      Error:
      ! `headers` must be a list, character vector, or raw.

# has nice print method

    Code
      as_headers(c("X:1", "Y: 2", "Z:"))
    Output
      <httr2_headers>
      X: 1
      Y: 2
      Z: 
    Code
      as_headers(list())
    Output
      <httr2_headers>

# print and str redact headers

    Code
      print(x)
    Output
      <httr2_headers>
      x: <REDACTED>
      y: 2
    Code
      str(x)
    Output
       <httr2_headers>
       $ x: <REDACTED>
       $ y: chr "2"

# new_headers checks inputs

    Code
      new_headers(1)
    Condition
      Error:
      ! `x` must be a list.
    Code
      new_headers(list(1))
    Condition
      Error:
      ! All elements of `x` must be named.
    Code
      new_headers(list(x = mean))
    Condition
      Error:
      ! Each element of `x` must be an atomic vector or a weakref.
      i `x[[1]]` is a function.

