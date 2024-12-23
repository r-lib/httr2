test_that("has useful default (with message)", {
  req <- request_test()
  expect_snapshot(req <- req_retry(req))
  expect_equal(retry_max_tries(req), 2)
  expect_equal(retry_max_seconds(req), Inf)
})

test_that("can set define maximum retries", {
  req <- request_test()
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
  req <- request_test()
  expect_equal(retry_is_transient(req, response(404)), FALSE)
  expect_equal(retry_is_transient(req, response(429)), TRUE)

  req <- req_retry(req, is_transient = ~ resp_status(.x) == 404)
  expect_equal(retry_is_transient(req, response(404)), TRUE)
  expect_equal(retry_is_transient(req, response(429)), FALSE)
})

test_that("can override default backoff", {
  withr::local_seed(1014)

  req <- request_test()
  expect_equal(retry_backoff(req, 1), 1.1)
  expect_equal(retry_backoff(req, 5), 26.9)
  expect_equal(retry_backoff(req, 10), 60)

  req <- req_retry(req, backoff = ~10)
  expect_equal(retry_backoff(req, 1), 10)
  expect_equal(retry_backoff(req, 5), 10)
  expect_equal(retry_backoff(req, 10), 10)
})

test_that("can override default retry wait", {
  resp <- response(429, headers = c("Retry-After: 10", "Wait-For: 20"))
  req <- request_test()
  expect_equal(retry_after(req, resp, 1), 10)

  req <- req_retry(req, after = ~ as.numeric(resp_header(.x, "Wait-For")))
  expect_equal(retry_after(req, resp, 1), 20)
})

test_that("missing retry-after uses backoff", {
  req <- request_test()
  req <- req_retry(req, backoff = ~10)

  expect_equal(retry_after(req, response(429), 1), 10)
})

test_that("useful message if `after` wrong", {
  req <- request_test() %>%
    req_retry(
      is_transient = function(resp) TRUE,
      after = function(resp) resp
    )

  expect_snapshot(req_perform(req), error = TRUE)
})

test_that("validates its inputs", {
  req <- new_request("http://example.com")

  expect_snapshot(error = TRUE, {
    req_retry(req, max_tries = 0)
    req_retry(req, max_tries = 2, max_seconds = "x")
    req_retry(req, max_tries = 2, retry_on_failure = "x")
  })
})

test_that("is_number_or_na implemented correctly", {
  expect_equal(is_number_or_na(1), TRUE)
  expect_equal(is_number_or_na(NA_real_), TRUE)
  expect_equal(is_number_or_na(NA), TRUE)

  expect_equal(is_number_or_na(1:2), FALSE)
  expect_equal(is_number_or_na(numeric()), FALSE)
  expect_equal(is_number_or_na("x"), FALSE)
})


# circuit breaker --------------------------------------------------------

test_that("triggered after specified requests", {
  req <- request_test("/status/:status", status = 429) %>%
    req_retry(
      after = \(resp) 0,
      max_tries = 10,
      failure_threshold = 1
    )

  # First attempt performs, retries, then errors
  req_perform(req) %>%
    expect_condition(class = "httr_perform") %>%
    expect_condition(class = "httr2_retry") %>%
    expect_error(class = "httr2_breaker")

  # Second attempt errors without performing
  req_perform(req) %>%
    expect_no_condition(class = "httr_perform") %>%
    expect_error(class = "httr2_breaker")

  # Attempt on same realm errors without trying at all
  req2 <- request_test("/status/:status", status = 200) |>
    req_retry()
  req_perform(req) %>%
    expect_no_condition(class = "httr_perform") %>%
    expect_error(class = "httr2_breaker")
})
