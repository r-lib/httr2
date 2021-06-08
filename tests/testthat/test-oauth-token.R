test_that("new token computes expires_at", {
  time <- Sys.time()
  token <- oauth_token("xyz", expires_in = 10, .date = time)
  expect_s3_class(token, "httr2_token")
  expect_equal(token$expires_at, as.numeric(time + 10))
})

test_that("can compute token expiry", {
  token <- oauth_token("xyz")
  expect_equal(token_has_expired(token), FALSE)

  # Respects delay
  token <- oauth_token("xyz", expires_in = 8, .date = Sys.time() - 10)
  expect_equal(token_has_expired(token), TRUE)

  token <- oauth_token("xyz", expires_in = 10, .date = Sys.time())
  expect_equal(token_has_expired(token), FALSE)
})
