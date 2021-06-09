test_that("oauth_app checks its inputs", {
  expect_snapshot(error = TRUE, {
    oauth_app(1)

    client <- oauth_client("id")
    oauth_app(client, endpoints = 1)
    oauth_app(client, endpoints = c("x" = "x"))

    oauth_app(client, endpoints = c("token" = "test"), auth = "header")
  })
})

test_that("can check app has needed pieces", {
  app <- oauth_app(oauth_client("id"), c("token" = "test"))
  expect_snapshot(error = TRUE, {
    oauth_flow_check_app(app, "test", is_confidential = TRUE)
    oauth_flow_check_app(app, "test", endpoints = "foo")
    oauth_flow_check_app(app, "test", interactive = TRUE)
  })
})

test_that("can set custom name", {
  client <- oauth_client("id", name = "test")
  app <- oauth_app(client, c("token" = "test"))
  expect_equal(oauth_client_name(app), "test")
})

test_that("client has useful print method", {
  expect_snapshot({
    oauth_client("x")
    oauth_client("x", "x")
  })
})

test_that("can authenticate using header or body", {
  req <- request("http://example.com")
  client <- oauth_client("id", "secret")
  ep <- c("token" = "test")

  req_h <- req_auth_oauth_client(req, oauth_app(client, ep, auth = "header"))
  expect_equal(req_h$options$userpwd, "id:secret")

  req_b <- req_auth_oauth_client(req, oauth_app(client, ep, auth = "body"))
  expect_equal(rawToChar(req_b$options$postfields), "client_id=id&client_secret=secret")
})
