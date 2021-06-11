
# cache -------------------------------------------------------------------

test_that("can get and set from cache", {
  req <- request("http://example.com") %>% req_cache(tempfile())
  resp <- response(200, headers = "Etag: ABC", body = charToRaw("abc"))

  expect_false(cache_exists(req))
  cache_set(req, resp)
  expect_true(cache_exists(req))
  expect_equal(cache_get(req), resp)

  # If path is null can leave resp as is
  expect_equal(cache_body(req, NULL), resp$body)
  # If path is set, need to save to path
  path <- tempfile()
  body <- cache_body(req, path)
  expect_equal(body, new_path(path))
  expect_equal(readLines(path, warn = FALSE), rawToChar(resp$body))
})

test_that("handles responses with files", {
  req <- request("http://example.com") %>% req_cache(tempfile())

  path <- local_write_lines("Hi there")
  resp <- response(200, headers = "Etag: ABC", body = new_path(path))
  cache_set(req, resp)

  # File should be copied in cache directory, and response body updated
  body_path <- cache_path(req, ".body")
  expect_equal(readLines(body_path), "Hi there")
  expect_equal(cache_get(req)$body, new_path(body_path))

  # If path is null, just leave body as is, since req_body() already
  # papers over the differences
  expect_equal(cache_body(req, NULL), new_path(body_path))

  # If path is not null, copy to desired location, and update body
  path2 <- tempfile()
  body <- cache_body(req, path2)
  expect_equal(readLines(body), "Hi there")
  expect_equal(body, new_path(path2))
})

# headers -----------------------------------------------------------------

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
