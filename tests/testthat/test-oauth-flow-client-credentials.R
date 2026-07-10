test_that("can configure token expiry margin", {
  client <- oauth_client("test", "https://example.com/token", secret = "secret")
  default_req <- request("https://example.com") |>
    req_oauth_client_credentials(client)
  req <- request("https://example.com") |>
    req_oauth_client_credentials(client, expiry_margin = 40)

  expect_equal(default_req$policies$auth_sign$params$expiry_margin, 30)
  expect_equal(req$policies$auth_sign$params$expiry_margin, 40)
})
