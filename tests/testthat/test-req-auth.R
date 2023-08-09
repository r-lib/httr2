test_that("can send username/password", {
  user <- "u"
  password <- "p"
  req1 <- request_test("/basic-auth/:user/:password")
  req2 <- req1 %>% req_auth_basic(user, password)

  expect_error(req_perform(req1), class = "httr2_http_401")
  expect_error(req_perform(req2), NA)
})

test_that("can send bearer token", {
  req <- req_auth_bearer_token(request_test(), "abc")
  expect_equal(req$headers, structure(list(Authorization = "Bearer abc"), redact = "Authorization"))
})
