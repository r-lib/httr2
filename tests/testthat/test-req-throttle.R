test_that("throttling causes delay", {
  throttle_reset()

  req <- request_test() %>% req_throttle(50 / 1)
  expect_equal(throttle_delay(req), 0)
  expect_true(throttle_delay(req) > 0.005)
})

test_that("throttling causes expected average request rate", {
  skip_on_cran()
  throttle_reset()

  req <- request_test() %>% req_throttle(10)

  elapsed <- replicate(20, system.time(req_perform(req)))["elapsed", ]

  trimmed <- mean(elapsed, trim = 0.10)

  expect_gt(trimmed, 0.08)
  expect_lt(trimmed, 0.12)
})

test_that("realm defaults to hostname but can be overridden", {
  throttle_reset()
  expect_equal(the$throttle, list())

  request_test() %>% req_throttle(100 / 1) %>% throttle_delay()
  expect_named(the$throttle, "127.0.0.1")

  throttle_reset()
  request_test() %>% req_throttle(100 / 1, "custom") %>% throttle_delay()
  expect_named(the$throttle, "custom")
})
