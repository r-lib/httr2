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

test_that("can override default is_transient", {
  req <- req_test("/get")
  expect_equal(retry_is_transient(req, response(404)), FALSE)
  expect_equal(retry_is_transient(req, response(429)), TRUE)

  req <- req_retry(req, is_transient = ~ resp_status(.x) == 404)
  expect_equal(retry_is_transient(req, response(404)), TRUE)
  expect_equal(retry_is_transient(req, response(429)), FALSE)
})

test_that("can override default backoff", {
  withr::local_seed(1014)

  req <- req_test("/get")
  expect_equal(retry_backoff(req, 1), 1.1)
  expect_equal(retry_backoff(req, 5), 26.9)
  expect_equal(retry_backoff(req, 10), 60)

  req <- req_retry(req, backoff = ~ 10)
  expect_equal(retry_backoff(req, 1), 10)
  expect_equal(retry_backoff(req, 5), 10)
  expect_equal(retry_backoff(req, 10), 10)
})

test_that("can override default retry wait", {
  resp <- response(429, headers = c("Retry-After: 10", "Wait-For: 20"))
  req <- req_test("/get")
  expect_equal(retry_after(req, resp, 1), 10)

  req <- req_retry(req, after = ~ as.numeric(resp_header(.x, "Wait-For")))
  expect_equal(retry_after(req, resp, 1), 20)
})

test_that("missing retry-after uses backoff", {
  req <- req_test("/get")
  req <- req_retry(req, backoff = ~ 10)

  expect_equal(retry_after(req, response(429), 1), 10)
})
