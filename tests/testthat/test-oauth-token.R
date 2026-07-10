test_that("new token computes expires_at", {
  withr::local_envvar(TZ = "UTC")

  time <- .POSIXct(1740000000)
  token <- oauth_token("xyz", expires_in = 10, .date = time)
  expect_s3_class(token, "httr2_token")
  expect_equal(token$expires_at, as.numeric(time + 10))
  expect_snapshot(token)
})

test_that("printing token redacts access, id and refresh token", {
  expect_snapshot({
    oauth_token(
      access_token = "secret",
      refresh_token = "secret",
      id_token = "secret"
    )
  })
})

test_that("can compute token expiry", {
  token <- oauth_token("xyz")
  expect_equal(token_has_expired(token), FALSE)

  token <- oauth_token("xyz", expires_in = 20, .date = Sys.time())
  expect_equal(token_has_expired(token), TRUE)
  expect_equal(token_has_expired(token, delay = 0), FALSE)

  token <- oauth_token("xyz", expires_in = 60, .date = Sys.time())
  expect_equal(token_has_expired(token), FALSE)
})
