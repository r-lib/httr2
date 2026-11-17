test_that("can send username/password", {
  user <- "u"
  password <- "p"
  req1 <- request_test("/basic-auth/:user/:password")
  req2 <- req1 |> req_auth_basic(user, password)
  expect_redacted(req2, "Authorization")

  expect_error(req_perform(req1), class = "httr2_http_401")
  expect_error(req_perform(req2), NA)
})

test_that("can send bearer token", {
  req <- req_auth_bearer_token(request_test(), "abc")
  expect_equal(
    headers_flatten(req$headers, redact = FALSE),
    list(Authorization = "Bearer abc")
  )
})

test_that("basic auth accepts secrets", {
  req <- request_test("/basic-auth/u/p") |>
    req_auth_basic("u", \() "p")
  expect_redacted(req, "Authorization")
  expect_error(req_perform(req), NA)
})

test_that("bearer token accepts secrets", {
  withr::local_envvar(SECRET_TOKEN_TEST = "abc")
  req <- request_test("/bearer") |>
    req_auth_bearer_token(secret_envvar("SECRET_TOKEN_TEST"))
  expect_error(req_perform(req), NA)
})

test_that("bearer token secret displays redacted", {
  req <- request("http://example.com") |>
    req_auth_bearer_token(secret_envvar("MY_TOKEN"))
  expect_snapshot(req)
})

test_that("auth secret is only resolved once per perform", {
  n <- 0
  req <- request_test("/bearer") |>
    req_auth_bearer_token(function() {
      n <<- n + 1
      "abc"
    })
  expect_error(req_perform(req), NA)
  expect_equal(n, 1)
})
