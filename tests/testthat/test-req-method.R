test_that("can override default method", {
  req <- request("http://example.com")

  expect_equal(req$method, NULL)

  req <- req_method(req, "patch")
  expect_equal(req$method, "PATCH")
})

test_that("correctly guesses default method", {
  req <- request("http://example.com")
  expect_equal(req_method_get(req), "GET")

  req <- req_body_raw(req, "abc")
  expect_equal(req_method_get(req), "POST")

  req <- req_options(req, nobody = TRUE)
  expect_equal(req_method_get(req), "HEAD")
})
