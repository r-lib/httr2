test_that("success request returns response", {
  resp <- req_test("/get") %>% req_fetch()
  expect_s3_class(resp, "httr2_response")
})

test_that("curl and http errors become errors", {
  req <- req_test("/delay/:secs", secs = 1) %>% req_timeout(0.1)
  expect_error(req_fetch(req), "timed out")

  req <- req_test("/status/:status", status = 404)
  expect_error(req_fetch(req), class = "httr2_http_404")

  # including transient errors
  req <- req_test("/status/:status", status = 429)
  expect_error(req_fetch(req), class = "httr2_http_429")
})

test_that("persistent HTTP errors only get single attempt", {
  req <- req_test("/status/:status", status = 404) %>%
    req_retry(max_tries = 5)

  cnd <- req_fetch(req) %>%
    expect_error(class = "httr2_http_404") %>%
    catch_cnd("httr2_fetch")
  expect_equal(cnd$n, 1)
})

test_that("repeated transient errors still fail", {
  req <- req_test("/status/:status", status = 429) %>%
    req_retry(max_tries = 3, backoff = ~ 0)

  cnd <- req_fetch(req) %>%
    expect_error(class = "httr2_http_429") %>%
    catch_cnd("httr2_fetch")
  expect_equal(cnd$n, 3)
})

test_that("req_fetch() will throttle requests", {
  throttle_reset()

  req <- req_test("/get") %>% req_throttle(10 / 1)
  cnd <- req %>% req_fetch() %>% catch_cnd("httr2_sleep")
  expect_null(cnd)

  cnd <- req %>% req_fetch("/get") %>% catch_cnd("httr2_sleep")
  expect_s3_class(cnd, "httr2_sleep")
  expect_gt(cnd$seconds, 0.002)
})
