# aws_v4_signature calculates correct signature

    Code
      signature
    Output
      $CanonicalRequest
      [1] "POST\n/v0/\n\nhost:example.execute-api.us-east-1.amazonaws.com\n\nhost\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
      
      $string_to_sign
      [1] "AWS4-HMAC-SHA256\n20250121T182222Z\n20250121/us-east-1/execute-api/aws4_request\n40b845bd8e6a316382ca9f73516e236075e4af2e04ebcb5f0d8eff12a040f6a4"
      
      $SigningKey
      sha256 hmac 56:b5:cd:6c:f3:27:c6:2c:ba:96:96:4c:45:3b:10:aa:97:11:7f:3d:dc:20:c0:58:d9:c4:07:7e:07:eb:63:58 
      
      $Authorization
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

