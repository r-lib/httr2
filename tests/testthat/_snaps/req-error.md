# failing callback still generates useful body

                                                     NULL 
                                                       "" 
                                                     NULL 
    "Additionally, req_error(body = ) failed with error:" 
                                                          
                                      "This is an error!" 

---

    Code
      req <- request("https://httpbin.org/status/404")
      req <- req %>% req_error(body = ~ resp_body_json(.x)$error)
      req %>% req_perform()
    Condition
      Error in `resp_check_status()`:
      ! HTTP 404 Not Found.
      
      Additionally, req_error(body = ) failed with error:
        Unexpected content type 'text/html'
        Expecting 'application/json'
        Or suffix '+json'
        i Override check with `check_type = FALSE`

