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
    oauth_client("abc", "http://x.com", key = "abc", auth = "jwt_sig")
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
