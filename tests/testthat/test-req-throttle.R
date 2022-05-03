test_that("throttling causes delay", {
  skip_on_cran()
  throttle_reset()

  req <- request_test() %>% req_throttle(50 / 1)
  expect_equal(throttle_delay(req), 0)
  expect_true(throttle_delay(req) > 0.005)
})

test_that("throttling causes expected average request rate", {
  skip_on_cran()
  throttle_reset()

  nps <- 20
  req <- request_test() %>% req_throttle(nps)
  times <- replicate(20, bench::system_time(req_perform(req)))["real", ]
  trimmed <- mean(times, trim = 0.2)

  expect_equal(trimmed, 1/nps, tolerance = 0.1)
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
