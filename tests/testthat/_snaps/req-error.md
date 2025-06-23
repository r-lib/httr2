# can customise error info

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! HTTP 404 Not Found.
      i Hi!

# long custom body is wrapped

    Code
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! HTTP 200 OK.
      i Ad aliquip et occaecat consequat eiusmod enim Lorem incididunt laboris deserunt. Consectetur magna ea ad quis dolore. Deserunt elit elit dolore magna fugiat ipsum id eu nostrud voluptate Lorem ad id anim. Cupidatat nulla ipsum irure nisi sunt ipsum commodo eu sint eiusmod consectetur.

# failing callback still generates useful body

    Failed to parse error body with method defined in `req_error()`.
    Caused by error:
    ! This is an error!

---

    Code
      req <- request_test("/status/404")
      req <- req_error(req, body = function(resp) resp_body_json(resp)$error)
      req_perform(req)
    Condition
      Error in `req_perform()`:
      ! Failed to parse error body with method defined in `req_error()`.
      Caused by error in `resp_body_json()`:
      ! Unexpected content type "text/plain".
      * Expecting type "application/json" or suffix "json".

