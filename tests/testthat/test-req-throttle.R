test_that("throttling affects request performance", {
  skip_on_cran()
  on.exit(throttle_reset())
  local_mocked_bindings(unix_time = function() 0)

  req <- request_test() |> req_throttle(capacity = 4, fill_time_s = 1)
  . <- replicate(4, req_perform(req))

  local_mocked_bindings(unix_time = function() 0.1)
  expect_snapshot(time <- system.time(req_perform(req))[[3]])
  expect_gte(time, 1 / 4 - 0.1 - 1e-6)
})

test_that("first request isn't throttled", {
  on.exit(throttle_reset())

  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  req <- request_test() |> req_throttle(rate = 1, fill_time_s = 1)
  expect_equal(throttle_delay(req), 0)

  mock_time <- 0.1
  expect_equal(throttle_delay(req), 0.9)

  mock_time <- 1.5
  expect_equal(throttle_delay(req), 0.5)
})

test_that("throttle only reset if parameters change", {
  on.exit(throttle_reset())

  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  req <- request_test() |> req_throttle(capacity = 1, fill_time_s = 1)
  expect_equal(throttle_delay(req), 0)

  mock_time <- 0.5
  expect_equal(throttle_delay(req), 0.5)
  mock_time <- 1

  req <- request_test() |> req_throttle(capacity = 1, fill_time_s = 1)
  expect_equal(throttle_delay(req), 1)

  # reset: capacity changed
  req <- request_test() |> req_throttle(capacity = 2, fill_time_s = 1)
  expect_equal(throttle_delay(req), 0)

  # reset: fill time changed
  req <- request_test() |> req_throttle(capacity = 2, fill_time_s = 2)
  expect_equal(throttle_delay(req), 0)
})


test_that("realm defaults to hostname but can be overridden", {
  on.exit(throttle_reset())

  expect_named(the$throttle, character())

  request_test() |> req_throttle(100 / 1)
  expect_named(the$throttle, "127.0.0.1")

  throttle_reset()
  request_test() |> req_throttle(100 / 1, realm = "custom")
  expect_named(the$throttle, "custom")
})

test_that("can enforce multiple limits in a single realm", {
  on.exit(throttle_reset())

  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  # 10 requests/second and 2 requests/minute
  req <- request_test() |>
    req_throttle(capacity = c(10, 2), fill_time_s = c(1, 60))
  expect_length(the$throttle[["127.0.0.1"]], 2)

  # first two are free
  expect_equal(throttle_delay(req), 0)
  expect_equal(throttle_delay(req), 0)

  # third must wait for the slow (minute) bucket, even though the fast
  # (second) bucket still has plenty of tokens
  expect_equal(throttle_delay(req), 30)
})

test_that("multiple limits recycle and accept rate", {
  on.exit(throttle_reset())

  request_test() |> req_throttle(capacity = c(4, 200), fill_time_s = c(1, 3600))
  buckets <- the$throttle[["127.0.0.1"]]
  expect_equal(map_dbl(buckets, function(b) b$capacity), c(4, 200))
  expect_equal(map_dbl(buckets, function(b) b$fill_rate), c(4, 200 / 3600))

  throttle_reset()
  request_test() |>
    req_throttle(rate = c(4, 200 / 3600), fill_time_s = c(1, 3600))
  buckets <- the$throttle[["127.0.0.1"]]
  expect_equal(map_dbl(buckets, function(b) b$capacity), c(4, 200))
})

test_that("throttle reset when number of limits changes", {
  on.exit(throttle_reset())

  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  request_test() |> req_throttle(capacity = 2, fill_time_s = 1)
  expect_length(the$throttle[["127.0.0.1"]], 1)

  request_test() |> req_throttle(capacity = c(2, 3), fill_time_s = c(1, 60))
  expect_length(the$throttle[["127.0.0.1"]], 2)
})

test_that("req_throttle checks its inputs", {
  expect_snapshot(error = TRUE, {
    request_test() |> req_throttle(capacity = "x")
    request_test() |> req_throttle(capacity = -1)
    request_test() |> req_throttle(capacity = 1.5)
    request_test() |> req_throttle(capacity = c(1, 2), fill_time_s = c(1, 2, 3))
  })
})

test_that("throttle_status reports each bucket", {
  on.exit(throttle_reset())
  local_mocked_bindings(unix_time = function() 0)

  request_test() |> req_throttle(capacity = c(2, 3), fill_time_s = c(1, 60))
  status <- throttle_status()
  expect_equal(status$realm, c("127.0.0.1", "127.0.0.1"))
  expect_equal(status$capacity, c(2, 3))
})

# token bucket ----------------------------------------------------------------

test_that("token bucket respects capacity limits", {
  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  bucket <- TokenBucket$new(capacity = 2, fill_rate = 2)
  expect_equal(bucket$take_token(), 0)
  expect_equal(bucket$tokens, 1)
  expect_equal(bucket$take_token(), 0)
  expect_equal(bucket$tokens, 0)

  expect_equal(bucket$take_token(), 0.5)
  mock_time <- 0.5
  expect_equal(bucket$take_token(), 0.5)
})

test_that("token bucket handles fractions correctly", {
  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  bucket <- TokenBucket$new(capacity = 2, fill_rate = 2)
  bucket$tokens <- 0
  expect_equal(bucket$take_token(), 0.5)
  expect_equal(bucket$tokens, -1)
  mock_time <- 0.5
  expect_equal(bucket$refill(), 0)

  bucket$last_fill <- 0
  bucket$tokens <- 0
  mock_time <- 0.4
  expect_equal(bucket$refill(), 0.80)
  expect_equal(bucket$take_token(), 0.1)
  mock_time <- mock_time + 0.1
  expect_equal(bucket$refill(), 0)
})

test_that("never returns negative time", {
  mock_time <- 0
  local_mocked_bindings(unix_time = function() mock_time)

  bucket <- TokenBucket$new(capacity = 5, fill_rate = 1)
  mock_time <- 5

  # first five are free
  replicate(5, expect_equal(bucket$take_token(), 0))

  # we get another 5 after 5 seconds
  mock_time <- mock_time + 5
  replicate(5, expect_equal(bucket$take_token(), 0))

  # if we only wait a second, we only get one
  mock_time <- mock_time + 1
  expect_equal(bucket$take_token(), 0)
  expect_equal(bucket$take_token(), 1)
  expect_equal(bucket$take_token(), 2)
})
