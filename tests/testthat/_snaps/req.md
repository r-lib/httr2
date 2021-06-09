# req has basic print method

    Code
      req <- request("https://example.com")
      req
    Message <cliMessage>
      <httr2_request>
      GET https://example.com
    Code
      req %>% req_body_raw("Test")
    Message <cliMessage>
      <httr2_request>
      POST https://example.com
      Headers:
      * Content-Type: ''
      Options:
      * post: TRUE
      * postfieldsize: 4
      * postfields: a raw vector
    Code
      req %>% req_body_multipart(list(Test = 1))
    Message <cliMessage>
      <httr2_request>
      GET https://example.com
      Fields:
      * Test: 1

# check_request() gives useful error

    Code
      check_request(1)
    Error <rlang_error>
      `req` must be an HTTP request object

