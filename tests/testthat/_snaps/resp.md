# response has basic print method

    Code
      response(200)
    Message
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: None
    Code
      response(200, headers = "Content-Type: text/html")
    Message
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Content-Type: text/html
      Body: None
    Code
      response(200, body = charToRaw("abcdef"))
    Message
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: In memory (6 bytes)
    Code
      response(200, body = new_path("path-empty"))
    Message
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: None
    Code
      response(200, body = new_path("path-content"))
    Message
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: On disk 'path-content' (15 bytes)

# response checks its inputs

    Code
      response(status_code = "abc")
    Condition
      Error in `response()`:
      ! `status_code` must be a whole number, not the string "abc".
    Code
      response(url = 1)
    Condition
      Error in `response()`:
      ! `url` must be a single string, not the number 1.
    Code
      response(method = 1)
    Condition
      Error in `response()`:
      ! `method` must be a single string or `NULL`, not the number 1.
    Code
      response(headers = 1)
    Condition
      Error in `response()`:
      ! `headers` must be a list, character vector, or raw.

# check_response produces helpful error

    Code
      check_response(1)
    Condition
      Error:
      ! `1` must be an HTTP response object, not the number 1.

