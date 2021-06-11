test_that("nothing happens if cache not enabled", {
  req <- request("http://example.com")

  expect_false(cache_exists(req))
  expect_equal(cache_pre_fetch(req), req)

  resp <- response()
  expect_equal(cache_post_fetch(req, resp), resp)
})

test_that("immutable objects retrieved directly from cache", {
  req <- request("http://example.com") %>% req_cache(tempfile())
  resp <- response(200,
    headers = "Expires: Wed, 01 Jan 3000 00:00:00 GMT",
    body = charToRaw("abc")
  )
  cache_set(req, resp)

  expect_equal(cache_pre_fetch(req), resp)
})

test_that("cached cache header added to request", {
  req <- request("http://example.com") %>% req_cache(tempfile())
  # If not cached, request returned as is
  req2 <- cache_pre_fetch(req)
  expect_equal(req2, req)

  resp <- response(200,
    headers = c('Etag: "abc"', "Last-Modified: Wed, 01 Jan 2020 00:00:00 GMT"),
    body = charToRaw("abc")
  )
  cache_set(req, resp)

  # After caching adds caching headers
  req3 <- cache_pre_fetch(req)
  expect_equal(req3$headers$`If-Modified-Since`, "Wed, 01 Jan 2020 00:00:00 GMT")
  expect_equal(req3$headers$`If-None-Match`, '"abc"')
})

test_that("error can use cached value", {
  req <- request("http://example.com") %>% req_cache(tempfile(), TRUE)
  resp <- response(200, body = charToRaw("OK"))
  cache_set(req, resp)

  cached <- cache_post_fetch(req, structure(list(), class = "error"))
  expect_equal(cached, resp)
})

test_that("304 retains headers but gets cached body", {
  req <- request("http://example.com") %>% req_cache(tempfile())
  resp <- response(200, headers = "X: 1", body = charToRaw("OK"))
  cache_set(req, resp)

  cached <- cache_post_fetch(req, response(304, headers = "X: 2"))
  expect_equal(cached$headers$x, "2")
  expect_equal(cached$body, resp$body)
})

test_that("automatically adds to cache", {
  req <- request("http://example.com") %>% req_cache(tempfile())
  expect_false(cache_exists(req))

  resp <- response(200, headers = 'Etag: "abc"', body = charToRaw("OK"))
  cached <- cache_post_fetch(req, resp)
  expect_true(cache_exists(req))
  expect_equal(cache_get(req), resp)
})

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

  expect_equal(is_cacheable(200, headers = "Expires: ABC"), TRUE)
  expect_equal(is_cacheable(200, headers = "Cache-Control: max-age=10"), TRUE)
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
