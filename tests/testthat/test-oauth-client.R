test_that("can check app has needed pieces", {
  client <- oauth_client("id", token_url = "http://example.com")
  expect_snapshot(error = TRUE, {
    oauth_flow_check("test", client, is_confidential = TRUE)
    oauth_flow_check("test", client, interactive = TRUE)
  })
})

test_that("client has useful print method", {
  expect_snapshot({
    oauth_client("x", token_url = "http://example.com")
    oauth_client("x", secret = "SECRET", token_url = "http://example.com")
  })
})

test_that("picks default auth", {
  expect_equal(
    oauth_client("x", "url", key = NULL)$auth,
    "oauth_client_req_auth_body")
  expect_equal(
    oauth_client("x", "url", key = "key")$auth,
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
  expect_equal(req_h$headers$Authorization, "Basic aWQ6c2VjcmV0")

  req_b <- oauth_client_req_auth(req, client("body"))
  expect_equal(rawToChar(req_b$options$postfields), "client_id=id&client_secret=secret")
})
