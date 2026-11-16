test_that("can configure token expiry margin", {
  client <- oauth_client("test", "https://example.com/token", secret = "secret")
  default_req <- request("https://example.com") |>
    req_oauth_client_credentials(client)
  req <- request("https://example.com") |>
    req_oauth_client_credentials(client, expiry_margin = 40)

  expect_equal(default_req$policies$auth_sign$params$expiry_margin, 30)
  expect_equal(req$policies$auth_sign$params$expiry_margin, 40)
})

test_that("cache key includes scope", {
  client <- oauth_client(
    "test-cc-cache",
    "https://example.com/token",
    secret = "secret"
  )
  credentials <- function(scope) {
    request("https://example.com") |>
      req_oauth_client_credentials(client, scope = scope)
  }

  cache_a <- credentials("a")$policies$auth_sign$cache
  cache_b <- credentials("b")$policies$auth_sign$cache
  withr::defer(cache_a$clear())

  cache_a$set("token-a")
  expect_equal(cache_b$get(), NULL)
})
