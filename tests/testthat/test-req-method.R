test_that("can override default method", {
  req <- request("http://example.com")

  expect_equal(req$method, NULL)

  req <- req_method(req, "patch")
  expect_equal(req$method, "PATCH")
})

test_that("correctly guesses default method", {
  req <- request("http://example.com")
  expect_equal(default_method(req), "GET")

  req <- req_options(req, post = TRUE)
  expect_equal(default_method(req), "POST")

  req <- req_options(req, nobody = TRUE)
  expect_equal(default_method(req), "HEAD")
})
