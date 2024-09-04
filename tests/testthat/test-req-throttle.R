test_that("first request isn't throttled", {
  skip_on_cran()
  throttle_reset()

  local_mocked_bindings(sys_sleep = function(...) {})
  req <- request_test() %>% req_throttle(1)

  local_mocked_bindings(unix_time = function() 0)
  expect_equal(throttle_delay(req), 0)

  local_mocked_bindings(unix_time = function() 0.1)
  expect_equal(throttle_delay(req), 0.9)

  local_mocked_bindings(unix_time = function() 1.5)
  expect_equal(throttle_delay(req), 0)
})

test_that("throttling causes expected average request rate", {
  skip_on_cran()
  skip_on_ci()
  throttle_reset()

  wait <- 0
  local_mocked_bindings(sys_sleep = function(seconds, ...) {
    wait <<- 0
  })

  nps <- 20
  req <- request_test() %>% req_throttle(20)
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
