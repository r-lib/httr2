# bearer token secret displays redacted

    Code
      req
    Output
      <httr2_request>
      GET http://example.com
      Headers:
      * Authorization: <REDACTED (env: MY_TOKEN)>
      Body: empty

