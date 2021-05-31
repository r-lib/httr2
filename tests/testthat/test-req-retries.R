test_that("can set define maximum retries", {
  req <- req_test("/get")
  expect_equal(retry_max_tries(req), 1)
  expect_equal(retry_max_seconds(req), Inf)

  req <- req_retry(req, max_tries = 2)
  expect_equal(retry_max_tries(req), 2)
  expect_equal(retry_max_seconds(req), Inf)

  req <- req_retry(req, max_seconds = 5)
  expect_equal(retry_max_tries(req), Inf)
  expect_equal(retry_max_seconds(req), 5)

  req <- req_retry(req, max_tries = 2, max_seconds = 5)
  expect_equal(retry_max_tries(req), 2)
  expect_equal(retry_max_seconds(req), 5)
})
