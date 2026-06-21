test_that("can check app has needed pieces", {
  client <- oauth_client("id", token_url = "http://example.com")
  expect_snapshot(error = TRUE, {
    oauth_flow_check("test", NULL)
    oauth_flow_check("test", client, is_confidential = TRUE)
    oauth_flow_check("test", client, interactive = TRUE)
  })
})

test_that("checks auth types have needed args", {
  expect_snapshot(error = TRUE, {
    oauth_client("abc", "http://x.com", auth = "header")
    oauth_client("abc", "http://x.com", auth = "jwt_sig")
    oauth_client("abc", "http://x.com", auth = 123)
  })
})

test_that("client has useful print method", {
  url <- "http://example.com"

  expect_snapshot({
    oauth_client("x", url)
    oauth_client("x", url, secret = "SECRET")
    oauth_client("x", url, auth = function(...) {
      xxx
    })
  })
})

test_that("metadata fills endpoints, explicit values win", {
  metadata <- structure(
    list(
      token_endpoint = "https://example.com/token",
      authorization_endpoint = "https://example.com/auth",
      device_authorization_endpoint = "https://example.com/device"
    ),
    class = "httr2_oauth_server_metadata"
  )

  client <- oauth_client("id", metadata = metadata)
  expect_equal(client$token_url, "https://example.com/token")
  expect_equal(client$auth_url, "https://example.com/auth")
  expect_equal(client$device_auth_url, "https://example.com/device")

  client <- oauth_client(
    "id",
    token_url = "https://other.com/token",
    metadata = metadata
  )
  expect_equal(client$token_url, "https://other.com/token")
  expect_equal(client$auth_url, "https://example.com/auth")
  expect_equal(client$device_auth_url, "https://example.com/device")
})

test_that("metadata is validated and token_url must be resolvable", {
  metadata <- structure(
    list(authorization_endpoint = "https://example.com/auth"),
    class = "httr2_oauth_server_metadata"
  )
  expect_snapshot(error = TRUE, {
    oauth_client("id")
    oauth_client("id", metadata = metadata)
    oauth_client("id", token_url = "https://x.com", metadata = list())
  })
})

test_that("picks default auth", {
  expect_equal(
    oauth_client("x", "url", key = NULL)$auth,
    "oauth_client_req_auth_body"
  )
  expect_equal(
    oauth_client(
      "x",
      "url",
      key = "key",
      auth_params = list(claim = list())
    )$auth,
    "oauth_client_req_auth_jwt_sig"
  )
})


test_that("can authenticate using header or body", {
  client <- function(auth) {
    oauth_client(
      id = "id",
      secret = "secret",
      token_url = "http://example.com",
      auth = auth
    )
  }

  req <- request("http://example.com")
  req_h <- oauth_client_req_auth(req, client("header"))
  expect_equal(
    headers_flatten(req_h$headers, redact = FALSE),
    list(Authorization = "Basic aWQ6c2VjcmV0")
  )

  req_b <- oauth_client_req_auth(req, client("body"))
  expect_equal(
    req_b$body$data,
    list(client_id = I("id"), client_secret = I("secret"))
  )
})

test_that("can authenticate using a signed jwt", {
  skip_if_not_installed("jose")
  skip_if_not_installed("openssl")

  client <- oauth_client(
    "id",
    "http://example.com",
    key = openssl::rsa_keygen(),
    auth = "jwt_sig",
    auth_params = list(claim = jwt_claim())
  )
  req <- oauth_client_req_auth(request("http://example.com"), client)
  expect_named(req$body$data, c("client_assertion", "client_assertion_type"))
})

test_that("jwt_sig auth requires a claim", {
  skip_if_not_installed("openssl")

  client <- oauth_client(
    "id",
    "http://example.com",
    key = openssl::rsa_keygen(),
    auth = "jwt_sig"
  )
  expect_snapshot(
    oauth_client_req_auth(request("http://example.com"), client),
    error = TRUE
  )
})
