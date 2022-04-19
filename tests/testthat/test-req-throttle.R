test_that("throttling causes delay", {
  throttle_reset()

  req <- request_test() %>% req_throttle(50 / 1)
  expect_equal(throttle_delay(req), 0)
  expect_true(throttle_delay(req) > 0.005)
})

test_that("20 requests at rate 4/s take ~5 seconds to run", {
  skip_on_cran()
  throttle_reset()

  req <- request_test() %>% req_throttle(4)

  # Ensure all 20 requests below will have to wait.
  req_perform(req)

  elapsed <- system.time(rep(list(req), 20) %>% lapply(req_perform))[[3]]

  expect_gt(elapsed, 4)
  expect_lt(elapsed, 6)
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
