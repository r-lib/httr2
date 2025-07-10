# response has basic print method

    Code
      response(200)
    Output
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: None
    Code
      response(200, headers = "Content-Type: text/html")
    Output
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Content-Type: text/html
      Body: None
    Code
      response(200, body = charToRaw("abcdef"))
    Output
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: In memory (6 bytes)
    Code
      response(200, body = new_path("path-empty"))
    Output
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: None
    Code
      response(200, body = new_path("path-content"))
    Output
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: On disk 'path-content' (15 bytes)
    Code
      response(200, body = streaming)
    Output
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Body: Streaming connection

# check_response produces helpful error

    Code
      check_response(1)
    Condition
      Error:
      ! `1` must be an HTTP response object, not the number 1.

# new_response() checks its inputs

    Code
      new_response(1)
    Condition
      Error:
      ! `method` must be a single string, not the number 1.
    Code
      new_response("GET", 1)
    Condition
      Error:
      ! `url` must be a single string, not the number 1.
    Code
      new_response("GET", "http://x.com", "x")
    Condition
      Error:
      ! `status_code` must be a whole number, not the string "x".
    Code
      new_response("GET", "http://x.com", 200, 1)
    Condition
      Error:
      ! `headers` must be a list, character vector, or raw.
    Code
      new_response("GET", "http://x.com", 200, list(), 1)
    Condition
      Error:
      ! `body` must be a raw vector, a path, or a <StreamingBody>, not the number 1.
    Code
      new_response("GET", "http://x.com", 200, list(), raw(), "x")
    Condition
      Error:
      ! `timing` must be a numeric vector or `NULL`, not the string "x".
    Code
      new_response("GET", "http://x.com", 200, list(), raw(), c(x = 1), 1)
    Condition
      Error:
      ! `request` must be an HTTP request object or `NULL`, not the number 1.

