# respinse has basic print method

    Code
      response(200)
    Message <cliMessage>
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Content-Type: NA
      Body: Empty
    Code
      response(200, headers = "Content-Type: text/html")
    Message <cliMessage>
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Content-Type: text/html
      Body: Empty
    Code
      response(200, body = charToRaw("abcdef"))
    Message <cliMessage>
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Content-Type: NA
      Body: In memory (6 bytes)
    Code
      response(200, body = new_path("/test"))
    Message <cliMessage>
      <httr2_response>
      GET https://example.com
      Status: 200 OK
      Content-Type: NA
      Body: On disk 'body'

# check_response produces helpful error

    Code
      check_response(1)
    Error <rlang_error>
      `resp` must be an HTTP response object

