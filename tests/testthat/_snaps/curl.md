# must be call to curl

    Code
      curl_args("echo foo")
    Condition
      Error in `curl_args()`:
      ! Expecting call to curl not 'echo'

# common headers can be removed

    Code
      cat(curl_prepare_headers(headers, simplify_headers = TRUE))
    Output
      req_headers(
        Accept = "application/vnd.api+json",
        `user-agent` = "agent",
      )
    Code
      cat(curl_prepare_headers(headers, simplify_headers = FALSE))
    Output
      req_headers(
        `Sec-Fetch-Dest` = "empty",
        `Sec-Fetch-Mode` = "cors",
        `sec-ch-ua-mobile` = "?0",
        Accept = "application/vnd.api+json",
        referer = "ref",
        `user-agent` = "agent",
      )

# can translate to httr calls

    Code
      curl_translate("curl http://x.com")
    Output
      request("http://x.com") %>% 
        req_perform()
    Code
      curl_translate("curl http://x.com -X DELETE")
    Output
      request("http://x.com") %>% 
        req_method("DELETE") %>% 
        req_perform()
    Code
      curl_translate("curl http://x.com -H A:1")
    Output
      request("http://x.com") %>% 
        req_headers(
          A = "1",
        ) %>% 
        req_perform()
    Code
      curl_translate("curl http://x.com -H 'A B:1'")
    Output
      request("http://x.com") %>% 
        req_headers(
          `A B` = "1",
        ) %>% 
        req_perform()
    Code
      curl_translate("curl http://x.com -u u:p")
    Output
      request("http://x.com") %>% 
        req_auth_basic("u", "p") %>% 
        req_perform()
    Code
      curl_translate("curl http://x.com --verbose")
    Output
      request("http://x.com") %>% 
        req_perform(verbosity = 1)

# can translate data

    Code
      curl_translate("curl http://example.com --data abcdef")
    Output
      request("http://example.com") %>% 
        req_body_raw("abcdef", "application/x-www-form-urlencoded") %>% 
        req_perform()
    Code
      curl_translate(
        "curl http://example.com --data abcdef -H Content-Type:text/plain")
    Output
      request("http://example.com") %>% 
        req_body_raw("abcdef", "text/plain") %>% 
        req_perform()

