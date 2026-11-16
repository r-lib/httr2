test_that("cache key includes exchange parameters", {
  client <- oauth_client(
    "test-te-cache",
    "https://example.com/token",
    secret = "secret"
  )
  exchange <- function(subject_token) {
    request("https://example.com") |>
      req_oauth_token_exchange(
        client,
        subject_token = subject_token,
        subject_token_type = "urn:ietf:params:oauth:token-type:id_token"
      )
  }

  cache_a <- exchange("a")$policies$auth_sign$cache
  cache_b <- exchange("b")$policies$auth_sign$cache
  withr::defer(cache_a$clear())

  cache_a$set("token-a")
  expect_equal(cache_b$get(), NULL)

  # But identical parameters share the cache
  cache_a2 <- exchange("a")$policies$auth_sign$cache
  expect_equal(cache_a2$get(), "token-a")
})
