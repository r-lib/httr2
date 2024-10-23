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
  signature_pieces <- strsplit(paste0("Authorization=", signature), ",")[[1]]

  known <- list(
    Authorization = "AWS4-HMAC-SHA256",
    Credential = "AKIAIOSFODNN7EXAMPLE/20120525/us-east-1/glacier/aws4_request",
    SignedHeaders = "host;x-amz-date;x-amz-glacier-version",
    Signature = "3ce5b2f2fffac9262b4da9256f8d086b4aaf42eba5f111c21681a65a127b7c2a"
  )
  known_signature <- paste0(names(known), "=", known)

  expect_equal(signature_pieces, known_signature)
})
