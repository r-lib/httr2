test_that("auth_url falls back to the client's device_auth_url, explicit wins", {
  metadata <- structure(
    list(
      token_endpoint = "https://example.com/token",
      device_authorization_endpoint = "https://example.com/device"
    ),
    class = "httr2_oauth_server_metadata"
  )
  client <- oauth_client("id", metadata = metadata)

  req <- req_oauth_device(request("https://example.com"), client)
  expect_equal(
    req$policies$auth_sign$params$flow_params$auth_url,
    "https://example.com/device"
  )

  req <- req_oauth_device(
    request("https://example.com"),
    client,
    auth_url = "https://other.com/device"
  )
  expect_equal(
    req$policies$auth_sign$params$flow_params$auth_url,
    "https://other.com/device"
  )
})

test_that("oauth_flow_device() resolves auth_url from the client", {
  client <- oauth_client("id", token_url = "https://example.com/token")
  expect_error(
    oauth_flow_device(client, open_browser = FALSE),
    "Must supply"
  )
})
