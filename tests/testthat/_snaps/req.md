# req has basic print method

    Code
      req <- request("https://example.com")
      req
    Message
      <httr2_request>
      GET https://example.com
      Body: empty
    Code
      req %>% req_body_raw("Test")
    Message
      <httr2_request>
      POST https://example.com
      Body: a string
    Code
      req %>% req_body_multipart(Test = 1)
    Message
      <httr2_request>
      POST https://example.com
      Body: multipart encoded data

# printing headers works with {}

    Code
      req_headers(request("http://test"), x = "{z}", `{z}` = "x")
    Message
      <httr2_request>
      GET http://test
      Headers:
      * x: "{z}"
      * {z}: "x"
      Body: empty

# individually prints repeated headers

    Code
      request("https://example.com") %>% req_headers(A = 1:3)
    Message
      <httr2_request>
      GET https://example.com
      Headers:
      * A: "1"
      * A: "2"
      * A: "3"
      Body: empty

# check_request() gives useful error

    Code
      check_request(1)
    Condition
      Error:
      ! `1` must be an HTTP request object, not the number 1.

