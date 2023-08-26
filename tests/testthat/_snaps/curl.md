# must be call to curl

    Code
      curl_args("echo foo")
    Condition
      Error in `curl_args()`:
      ! Expecting call to curl not 'echo'

# common headers can be removed

    Code
      print(curl_simplify_headers(headers, simplify_headers = TRUE))
    Message
      <httr2_headers>
    Output
      Accept: application/vnd.api+json
      user-agent: agent
    Code
      print(curl_simplify_headers(headers, simplify_headers = FALSE))
    Message
      <httr2_headers>
    Output
      Sec-Fetch-Dest: empty
      Sec-Fetch-Mode: cors
      sec-ch-ua-mobile: ?0
      Accept: application/vnd.api+json
      referer: ref
      user-agent: agent

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

# can translate query

    Code
      curl_translate("curl http://x.com?string=abcde&b=2")
    Output
      request("http://x.com") %>% 
        req_url_query(
          string = "abcde",
          b = "2",
        ) %>% 
        req_perform()

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

# can read from clipboard

    Code
      curl_translate()
    Message
      v Copying to clipboard:
    Output
      request("http://example.com") %>% 
        req_headers(
          A = "1",
          B = "2",
        ) %>% 
        req_perform()
    Code
      clipr::read_clip()
    Output
      [1] "request(\"http://example.com\") %>% "
      [2] "  req_headers("                      
      [3] "    A = \"1\","                      
      [4] "    B = \"2\","                      
      [5] "  ) %>% "                            
      [6] "  req_perform()"                     

# encode_string2() produces simple strings

    Code
      curl_translate(cmd)
    Output
      request("http://example.com") %>% 
        req_method("PATCH") %>% 
        req_body_raw('{"data":{"x":1,"y":"a","nested":{"z":[1,2,3]}}}', "application/json") %>% 
        req_perform()

