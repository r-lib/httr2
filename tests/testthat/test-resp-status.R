test_that("get some useful output from WWW-Authenticate header", {
  resp <- response(
    401,
    headers = 'WWW-Authenticate: Bearer realm="example",error="invalid_token",error_description="The access token expired"'
  )
  expect_snapshot_error(resp_check_status(resp))

  resp <- response(
    403,
    headers = 'WWW-Authenticate: Bearer realm="https://accounts.google.com/", error="insufficient_scope", scope="https://www.googleapis.com/auth/iam https://www.googleapis.com/auth/cloud-platform"'
  )
  expect_snapshot_error(resp_check_status(resp))
})
