# failing callback still generates useful body

    [1] ""                                                   
    [2] "Additionally, req_error(body = ) failed with error:"
    [3] "This is an error!"                                  

---

    Code
      req <- request("https://httpbin.org/status/404")
      req <- req %>% req_error(body = ~resp_body_json(.x)$error)
      req %>% req_perform()
    Error <httr2_http_404>
      HTTP 404 Not Found.
      * 
      * Additionally, req_error(body = ) failed with error:
      * Unexpected content type 'text/html'
        * Expecting 'application/json'
        * Or suffix '+json'
        i Override check with `check_type = FALSE`

