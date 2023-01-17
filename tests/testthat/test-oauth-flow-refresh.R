test_that("cache considers refresh_token", {
  client <- oauth_client("example", "https://example.com/get_token")
  req <- request("https://example.com")

  # create 2 requests with different refresh token
  req1 <- req %>%
    req_oauth_refresh(client, refresh_token = "rt1")
  req2 <- req %>%
    req_oauth_refresh(client, refresh_token = "rt2")

  # cache must be empty
  expect_equal(req1$policies$auth_oauth$cache$get(), NULL)
  expect_equal(req2$policies$auth_oauth$cache$get(), NULL)

  # simulate that we made a request and got back a token
  token <- oauth_token(
    access_token = "a",
    token_type = "bearer",
    expires_in = NULL,
    refresh_token = "rt1",
    .date = Sys.time()
  )
  # ... that is now cached
  req1$policies$auth_oauth$cache$set(token)

  # req1 cache must be filled, but req2 cache still be empty
  expect_equal(req1$policies$auth_oauth$cache$get(), token)
  expect_equal(req2$policies$auth_oauth$cache$get(), NULL)
})
