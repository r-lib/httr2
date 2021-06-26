# as_headers errors on invalid types

    Code
      as_headers(1)
    Error <rlang_error>
      `headers` must be a list, character vector, or raw

# has nice print method

    Code
      as_headers(c("X:1", "Y: 2", "Z:"))
    Message <cliMessage>
      <httr2_headers>
    Output
      X: 1
      Y: 2
      Z: 
    Code
      as_headers(list())
    Message <cliMessage>
      <httr2_headers>

# new_headers checks inputs

    Code
      new_headers(1)
    Error <rlang_error>
      `x` must be a list
    Code
      new_headers(list(1))
    Error <rlang_error>
      All elements of `x` must be named

