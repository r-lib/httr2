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

# check_response produces helpful error

    Code
      check_response(1)
    Condition
      Error in `check_response()`:
      ! `resp` must be an HTTP response object

