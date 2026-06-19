test_that("can correctly sign a request with dummy credentials", {
  req <- request("https://sts.amazonaws.com/")
  req <- req_auth_aws_v4(
    req,
    aws_access_key_id = "AKIAIOSFODNN7EXAMPLE",
    aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  )
  req <- req_body_form(
    req,
    Action = "GetCallerIdentity",
    Version = "2011-06-15"
  )
  expect_error(req_perform(req), class = "httr2_http_403")

  # And can clear non-existant cache
  expect_no_error(req_auth_clear_cache(req))
})

test_that("clear error if body type is unsupported", {
  req <- request("https://sts.amazonaws.com/")
  req <- req_auth_aws_v4(
    req,
    aws_access_key_id = "AKIAIOSFODNN7EXAMPLE",
    aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  )
  req <- req_body_multipart(req, x = "y")
  expect_snapshot(req_perform(req), error = TRUE)
})

test_that("can correctly sign a request with live credentials", {
  skip_if_not(has_paws_credentials())
  creds <- paws.common::locate_credentials()

  # https://docs.aws.amazon.com/STS/latest/APIReference/API_GetCallerIdentity.html
  req <- request("https://sts.amazonaws.com/")
  req <- req_auth_aws_v4(
    req,
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

test_that('aws_v4_signature calculates correct signature', {
  req <- request("https://example.execute-api.us-east-1.amazonaws.com/v0/") |>
    req_method('POST')

  body_sha256 <- openssl::sha256(req_get_body(req) %||% "")
  current_time <- as.POSIXct(1737483742, origin = "1970-01-01", tz = "EST")

  signature <- aws_v4_signature(
    method = req_get_method(req),
    url = req$url,
    headers = req$headers,
    body_sha256 = body_sha256,
    current_time = current_time,
    aws_service = 'execute-api',
    aws_region = 'us-east-1',
    aws_access_key_id = 'AKIAIOSFODNN7EXAMPLE',
    aws_secret_access_key = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
  )
  expect_snapshot(signature)
})

test_that("signing agrees with glacier example", {
  # Example from
  # https://docs.aws.amazon.com/amazonglacier/latest/dev/amazon-glacier-signing-requests.html

  signature <- aws_v4_signature(
    method = "PUT",
    url = "https://glacier.us-east-1.amazonaws.com/-/vaults/examplevault",
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

test_that("S3 canonical URI uses single-encoding", {
  signature <- aws_v4_signature(
    method = "GET",
    url = "https://s3.us-east-1.amazonaws.com/my-bucket/my%20file.txt",
    headers = list("x-amz-date" = "20250121T182222Z"),
    body_sha256 = openssl::sha256(""),
    current_time = as.POSIXct("2025-01-21 18:22:22", tz = "UTC"),
    aws_access_key_id = "AKIAIOSFODNN7EXAMPLE",
    aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  )

  canonical_uri <- strsplit(signature$CanonicalRequest, "\n")[[1]][[2]]
  expect_equal(canonical_uri, "/my-bucket/my%20file.txt")
})

test_that("non-S3 canonical URI double-encodes path segments", {
  # A URL where %2F is part of a path segment (e.g. an ARN), not a separator
  url_with_encoded_slash <- paste0(
    "https://bedrock-runtime.us-east-1.amazonaws.com/model/",
    "arn%3Aaws%3Abedrock%3Aus-east-1%3A123456%3A",
    "application-inference-profile%2Fprofile-id",
    "/converse"
  )

  signature <- aws_v4_signature(
    method = "POST",
    url = url_with_encoded_slash,
    headers = list("x-amz-date" = "20250121T182222Z"),
    body_sha256 = openssl::sha256(""),
    current_time = as.POSIXct("2025-01-21 18:22:22", tz = "UTC"),
    aws_access_key_id = "AKIAIOSFODNN7EXAMPLE",
    aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  )

  # %2F in the ARN is double-encoded to %252F, not treated as a separator
  canonical_uri <- strsplit(signature$CanonicalRequest, "\n")[[1]][[2]]
  expect_equal(
    canonical_uri,
    paste0(
      "/model/",
      "arn%253Aaws%253Abedrock%253Aus-east-1%253A123456%253A",
      "application-inference-profile%252Fprofile-id",
      "/converse"
    )
  )
})

test_that("canonical URI preserves trailing slash", {
  signature <- aws_v4_signature(
    method = "GET",
    url = "https://example.execute-api.us-east-1.amazonaws.com/v0/",
    headers = list("x-amz-date" = "20250121T182222Z"),
    body_sha256 = openssl::sha256(""),
    current_time = as.POSIXct("2025-01-21 18:22:22", tz = "UTC"),
    aws_service = "execute-api",
    aws_region = "us-east-1",
    aws_access_key_id = "AKIAIOSFODNN7EXAMPLE",
    aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  )

  canonical_uri <- strsplit(signature$CanonicalRequest, "\n")[[1]][[2]]
  expect_equal(canonical_uri, "/v0/")
})
