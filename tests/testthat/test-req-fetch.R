test_that("success request returns response", {
  resp <- request_test("/get") %>% req_fetch()
  expect_s3_class(resp, "httr2_response")
})

test_that("curl and http errors become errors", {
  req <- request_test("/delay/:secs", secs = 1) %>% req_timeout(0.1)
  expect_error(req_fetch(req), class = "httr2_failed")

  req <- request_test("/status/:status", status = 404)
  expect_error(req_fetch(req), class = "httr2_http_404")

  # including transient errors
  req <- request_test("/status/:status", status = 429)
  expect_error(req_fetch(req), class = "httr2_http_429")
})

test_that("persistent HTTP errors only get single attempt", {
  req <- request_test("/status/:status", status = 404) %>%
    req_retry(max_tries = 5)

  cnd <- req_fetch(req) %>%
    expect_error(class = "httr2_http_404") %>%
    catch_cnd("httr2_fetch")
  expect_equal(cnd$n, 1)
})

test_that("repeated transient errors still fail", {
  req <- request_test("/status/:status", status = 429) %>%
    req_retry(max_tries = 3, backoff = ~ 0)

  cnd <- req_fetch(req) %>%
    expect_error(class = "httr2_http_429") %>%
    catch_cnd("httr2_fetch")
  expect_equal(cnd$n, 3)
})

test_that("can cache requests with etags", {
  req <- request_test("/etag/:etag", etag = "abc") %>% req_cache(tempfile())

  resp1 <- req_fetch(req)
  expect_condition(resp2 <- req_fetch(req), class = "httr2_cache_not_modified")
})

test_that("req_fetch() will throttle requests", {
  throttle_reset()

  req <- request_test("/get") %>% req_throttle(10 / 1)
  cnd <- req %>% req_fetch() %>% catch_cnd("httr2_sleep")
  expect_null(cnd)

  cnd <- req %>% req_fetch("/get") %>% catch_cnd("httr2_sleep")
  expect_s3_class(cnd, "httr2_sleep")
  expect_gt(cnd$seconds, 0.002)
})

test_that("can retrieve last request and response", {
  req <- request_test("/get")
  resp <- req_fetch(req)

  expect_equal(last_request(), req)
  expect_equal(last_response(), resp)
})

test_that("can last response is NULL if it fails", {
  req <- request("frooble")
  try(req_fetch(req), silent = TRUE)

  expect_equal(last_request(), req)
  expect_equal(last_response(), NULL)
})

# dry run -----------------------------------------------------------------

test_that("req_dry_run() returns useful data", {
  resp <- request("http://example.com") %>% req_dry_run(quiet = TRUE)
  expect_equal(resp$method, "GET")
  expect_equal(resp$path, "/")
  expect_equal(resp$headers$`user-agent`, default_ua())
})

test_that("authorization headers are redacted", {
  expect_snapshot({
    request("http://example.com") %>%
      req_auth_basic("user", "password") %>%
      req_user_agent("test") %>%
      req_dry_run()
  })
})

