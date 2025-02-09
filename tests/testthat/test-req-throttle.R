test_that("throttling affects request performance", {
  skip_on_cran()
  on.exit(throttle_reset())
  local_mocked_bindings(unix_time = function() 0)

  req <- request_test() %>% req_throttle(capacity = 4, fill_time_s = 1)
  . <- replicate(4, req_perform(req))

  local_mocked_bindings(unix_time = function() 0.1)
  expect_snapshot(time <- system.time(req_perform(req))[[3]])
  expect_gte(time, 1/4 - 0.1)
})

test_that("first request isn't throttled", {
  skip_on_cran()
  on.exit(throttle_reset())

  mock_time <- 0
  local_mocked_bindings(
    unix_time = function() mock_time,
    sys_sleep = function(...) {}
  )

  req <- request_test() %>% req_throttle(rate = 1, fill_time_s = 1)
  expect_equal(throttle_delay(req), 0)

  mock_time <- 0.1
  expect_equal(throttle_delay(req), 0.9)

  mock_time <- 1.5
  expect_equal(throttle_delay(req), 0)
})

test_that("realm defaults to hostname but can be overridden", {
  on.exit(throttle_reset())

  expect_named(the$throttle, character())

  request_test() %>% req_throttle(100 / 1) %>% throttle_delay()
  expect_named(the$throttle, "127.0.0.1")

  throttle_reset()
  request_test() %>% req_throttle(100 / 1, realm = "custom") %>% throttle_delay()
  expect_named(the$throttle, "custom")
})

# token bucket ----------------------------------------------------------------

test_that("token bucket respects capacity limits", {
  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  bucket <- TokenBucket$new(capacity = 2, fill_time_s = 1)
  expect_equal(bucket$wait_for_token(), 0)
  expect_equal(bucket$tokens, 1)
  expect_equal(bucket$wait_for_token(), 0)
  expect_equal(bucket$tokens, 0)

  expect_equal(bucket$wait_for_token(), 0.5)

  mock_time <- 0.5
  expect_equal(bucket$wait_for_token(), 0)
})

test_that("token bucket handles fractions correctly", {
  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  bucket <- TokenBucket$new(capacity = 2, fill_time_s = 1)
  bucket$wait_for_token(); bucket$wait_for_token()
  expect_equal(bucket$tokens, 0)

  expect_equal(bucket$wait_for_token(), 0.5)
  mock_time <- 0.1
  expect_equal(bucket$wait_for_token(), 0.4)
  expect_equal(bucket$tokens, 0.2)
  mock_time <- 0.2
  expect_equal(bucket$wait_for_token(), 0.3)
  expect_equal(bucket$tokens, 0.4)
  mock_time <- 0.5
  expect_equal(bucket$wait_for_token(), 0)
  expect_equal(bucket$tokens, 0)
})
