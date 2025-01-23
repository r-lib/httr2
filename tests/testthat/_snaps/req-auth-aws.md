# aws_v4_signature calculates correct signature

    Code
      rawToChar(signature$SigningKey)
    Output
      [1] "V\xb5\xcdl\xf3'\xc6,\xba\x96\x96LE;\020\xaa\x97\021\177=\xdc \xc0X\xd9\xc4\a~\a\xebcX"

---

    Code
      signature$CanonicalRequest
    Output
      [1] "POST\n/v0/\n\nhost:example.execute-api.us-east-1.amazonaws.com\n\nhost\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

---

    Code
      signature$string_to_sign
    Output
      [1] "AWS4-HMAC-SHA256\n20250121T182222Z\n20250121/us-east-1/execute-api/aws4_request\n40b845bd8e6a316382ca9f73516e236075e4af2e04ebcb5f0d8eff12a040f6a4"

---

    Code
      signature$Authorization
    Output
      [1] "AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20250121/us-east-1/execute-api/aws4_request,SignedHeaders=host,Signature=db2ef1ec9fd9efa801b8eb6b3e754d9d2d5d46189833a947c5427dd706f9534c"

# validates its inputs

    Code
      req_auth_aws_v4(1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `req` must be an HTTP request object, not the number 1.
    Code
      req_auth_aws_v4(req, 1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `aws_access_key_id` must be a single string, not the number 1.
    Code
      req_auth_aws_v4(req, "", "", aws_session_token = 1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `aws_session_token` must be a single string or `NULL`, not the number 1.
    Code
      req_auth_aws_v4(req, "", "", aws_service = 1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `aws_service` must be a single string or `NULL`, not the number 1.
    Code
      req_auth_aws_v4(req, "", "", aws_region = 1)
    Condition
      Error in `req_auth_aws_v4()`:
      ! `aws_region` must be a single string or `NULL`, not the number 1.

