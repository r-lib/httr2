# empty body generates error

    Code
      resp_body_raw(resp1)
    Condition
      Error in `resp_body_raw()`:
      ! Can't retrieve empty body.

---

    Code
      resp_body_raw(resp2)
    Condition
      Error in `resp_body_raw()`:
      ! Can't retrieve empty body.

# check argument types before caching

    Code
      resp_body_json(1)
    Condition
      Error in `resp_body_json()`:
      ! `resp` must be an HTTP response object, not the number 1.
    Code
      resp_body_xml(1)
    Condition
      Error in `resp_body_xml()`:
      ! `resp` must be an HTTP response object, not the number 1.

# content types are checked

    Code
      resp_body_json(req_perform(request_test("/xml")))
    Condition
      Error in `resp_body_json()`:
      ! Unexpected content type "application/xml".
      * Expecting type "application/json" or suffix "json".
    Code
      resp_body_xml(req_perform(request_test("/json")))
    Condition
      Error in `resp_body_xml()`:
      ! Unexpected content type "application/json".
      * Expecting type "application/xml" or "text/xml" or suffix "xml".

# multipart_boundary() follows RFC 2046

    Code
      boundary(no_boundary)
    Condition
      Error in `boundary()`:
      ! Missing or invalid multipart boundary "".
    Code
      boundary(empty_boundary)
    Condition
      Error in `boundary()`:
      ! Missing or invalid multipart boundary "".
    Code
      boundary(bad_char)
    Condition
      Error in `boundary()`:
      ! Missing or invalid multipart boundary "a@b".
    Code
      boundary(too_long)
    Condition
      Error in `boundary()`:
      ! Missing or invalid multipart boundary "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa".

# resp_body_multipart() generates parsing errors

    Code
      resp_body_multipart(wrong_type)
    Condition
      Error in `resp_body_multipart()`:
      ! Unexpected content type "text/html".
      * Expecting type "multipart/*"
    Code
      resp_body_multipart(no_close)
    Condition
      Error in `resp_body_multipart()`:
      ! Failed to find any parts in multipart response body.
    Code
      resp_body_multipart(no_open)
    Condition
      Error in `resp_body_multipart()`:
      ! Failed to find any parts in multipart response body.
    Code
      resp_body_multipart(no_header_line)
    Condition
      Error in `resp_body_multipart()`:
      ! Failed to parse per-part headers in a multipart response.
    Code
      resp_body_multipart(no_header_end)
    Condition
      Error in `resp_body_multipart()`:
      ! Failed to parse per-part headers in a multipart response.

