test_that("correctly determines if response is cacheable", {
  is_cacheable <- function(...) {
    resp_is_cacheable(response(...))
  }

  expect_equal(is_cacheable(200, headers = "Etag: ABC"), TRUE)
  expect_equal(is_cacheable(200, headers = c("Etag: ABC", "Cache-Control: no-store")), FALSE)
  expect_equal(is_cacheable(200), FALSE)
  expect_equal(is_cacheable(404), FALSE)
  expect_equal(is_cacheable(method = "POST"), FALSE)
})

test_that("can extract cache info with correct types", {
  resp <- response(headers = c(
    "Expires: Wed, 01 Jan 2020 00:00:00 GMT",
    "Last-Modified: Wed, 01 Jan 2010 00:00:00 GMT",
    "Etag: \"abc\""
  ))
  info <- resp_cache_info(resp)

  expect_equal(info$expires, local_time("2020-01-01"))
  # passed as is back to server, so leave as string
  expect_equal(info$last_modified, "Wed, 01 Jan 2010 00:00:00 GMT")
  # quotes are part of the etag string
  expect_equal(info$etag, '"abc"')
})

test_that("can extract various expiry values", {
  # Prefer Date + max-age
  resp1 <- response(headers = c(
    "Date: Wed, 01 Jan 2020 00:00:00 GMT",
    "Cache-Control: max-age=3600",
    "Expiry: Wed, 01 Jan 2020 00:00:00 GMT"
  ))
  expect_equal(resp_cache_expires(resp1), local_time("2020-01-01 01:00"))

  # Fall back to Expires
  resp2 <- response(headers = c(
    "Expires: Wed, 01 Jan 2020 00:00:00 GMT"
  ))
  expect_equal(resp_cache_expires(resp2), local_time("2020-01-01 00:00"))

  # Returns NA if no expiry
  resp2 <- response()
  expect_equal(resp_cache_expires(resp2), NA)
})
