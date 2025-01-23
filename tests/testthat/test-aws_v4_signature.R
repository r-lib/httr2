test_that('aws_v4_signature calculates correct signature', {
  req <- request("https://example.execute-api.us-east-1.amazonaws.com/v0/") |>
    req_method('POST')
  
  body_sha256 <- openssl::sha256(httr2:::req_body_get(req))
  current_time <- as.POSIXct(1737483742)
  
  signature <- httr2:::aws_v4_signature(
    method = httr2:::req_method_get(req),
    url = url_parse(req$url),
    headers = req$headers,
    body_sha256 = body_sha256,
    current_time = current_time,
    aws_service = 'execute-api',
    aws_region = 'us-east-1',
    aws_access_key_id = 'AKIAIOSFODNN7EXAMPLE',
    aws_secret_access_key = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
  )
  
  CanonicalRequest <- 
"POST
/v0/

host:example.execute-api.us-east-1.amazonaws.com

host
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  
  expect_equal(rawToChar(signature$SigningKey), "V\xb5\xcdl\xf3'\xc6,\xba\x96\x96LE;\020\xaa\x97\021\177=\xdc \xc0X\xd9\xc4\a~\a\xebcX")
  expect_equal(signature$CanonicalRequest, CanonicalRequest)
  expect_equal(signature$string_to_sign, "AWS4-HMAC-SHA256\n20250121T182222Z\n20250121/us-east-1/execute-api/aws4_request\n40b845bd8e6a316382ca9f73516e236075e4af2e04ebcb5f0d8eff12a040f6a4")
  expect_equal(signature$Authorization, "AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20250121/us-east-1/execute-api/aws4_request,SignedHeaders=host,Signature=db2ef1ec9fd9efa801b8eb6b3e754d9d2d5d46189833a947c5427dd706f9534c")
})