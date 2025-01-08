test_that("can correctly sign a request", {
  skip_if_not(has_paws_credentials())
  creds <- paws.common::locate_credentials()

  # https://docs.aws.amazon.com/STS/latest/APIReference/API_GetCallerIdentity.html
  req <- request("https://sts.amazonaws.com/")
  req <- req_auth_aws_v4(req,
    aws_access_key_id = creds$access_key_id,
    aws_secret_access_key = creds$secret_access_key,
    aws_session_token = creds$session_token,
    aws_region = creds$region
  )
  req <- req_body_form(
    req,
    Action = "GetCallerIdentity",
    Version = "2011-06-15"
  )
  expect_no_error(req_perform(req))
})

test_that("signing agrees with glacier example", {
  # Example from
  # https://docs.aws.amazon.com/amazonglacier/latest/dev/amazon-glacier-signing-requests.html

  signature <- aws_v4_signature(
    method = "PUT",
    url = url_parse("https://glacier.us-east-1.amazonaws.com/-/vaults/examplevault"),
    headers = list(
      "x-amz-date" = "20120525T002453Z",
      "x-amz-glacier-version" = "2012-06-01"
    ),
    body_sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    current_time = as.POSIXct("2012-05-25 00:24:53", tz = "UTC"),
    aws_access_key_id = "AKIAIOSFODNN7EXAMPLE",
    aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  )

  expected <- paste0(
    "AWS4-HMAC-SHA256 ",
    "Credential=AKIAIOSFODNN7EXAMPLE/20120525/us-east-1/glacier/aws4_request,",
    "SignedHeaders=host;x-amz-date;x-amz-glacier-version,",
    "Signature=3ce5b2f2fffac9262b4da9256f8d086b4aaf42eba5f111c21681a65a127b7c2a"
  )

  expect_equal(signature$Authorization, expected)
})

test_that("validates its inputs", {
  req <- request("https://sts.amazonaws.com/")
  expect_snapshot(error = TRUE, {
    req_auth_aws_v4(1)
    req_auth_aws_v4(req, 1)
    req_auth_aws_v4(req, "", "", aws_session_token = 1)
    req_auth_aws_v4(req, "", "", aws_service = 1)
    req_auth_aws_v4(req, "", "", aws_region = 1)
  })
})
