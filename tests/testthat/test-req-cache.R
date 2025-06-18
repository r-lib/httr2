test_that("nothing happens if cache not enabled", {
  req <- request("http://example.com")
  expect_equal(cache_pre_fetch(req), req)

  resp <- response()
  expect_equal(cache_post_fetch(req, resp), resp)
})

test_that("never retrieves POST request from cache", {
  req <- request("http://example.com") |>
    req_method("POST") |>
    req_cache(tempfile())

  # Fake an equivalent GET request in the cache
  resp <- response(
    200,
    headers = "Expires: Wed, 01 Jan 3000 00:00:00 GMT",
    body = charToRaw("abc")
  )
  cache_set(req, resp)

  expect_equal(cache_pre_fetch(req), req)
})

test_that("immutable objects retrieved directly from cache", {
  req <- request("http://example.com") |> req_cache(tempfile())
  resp <- response(
    200,
    headers = "Expires: Wed, 01 Jan 3000 00:00:00 GMT",
    body = charToRaw("abc")
  )
  cache_set(req, resp)

  expect_equal(cache_pre_fetch(req), resp)
})

test_that("cached cache header added to request", {
  req <- request("http://example.com") |> req_cache(tempfile())
  # If not cached, request returned as is
  req2 <- cache_pre_fetch(req)
  expect_equal(req2, req)

  resp <- response(
    200,
    headers = c('Etag: "abc"', "Last-Modified: Wed, 01 Jan 2020 00:00:00 GMT"),
    body = charToRaw("abc")
  )
  cache_set(req, resp)

  # After caching adds caching headers
  req3 <- cache_pre_fetch(req)
  expect_equal(
    req3$headers$`If-Modified-Since`,
    "Wed, 01 Jan 2020 00:00:00 GMT"
  )
  expect_equal(req3$headers$`If-None-Match`, '"abc"')
})

test_that("error can use cached value", {
  req <- request("http://example.com") |> req_cache(tempfile())
  resp <- response(200, body = charToRaw("OK"))
  cache_set(req, resp)

  expect_equal(cache_post_fetch(req, error_cnd()), error_cnd())

  req$policies$cache_use_on_error <- TRUE
  expect_equal(cache_post_fetch(req, error_cnd()), resp)
})

test_that("304 retains headers but gets cached body", {
  req <- request("http://example.com") |> req_cache(tempfile())
  resp <- response(200, headers = "X: 1", body = charToRaw("OK"))
  cache_set(req, resp)

  cached <- cache_post_fetch(req, response(304, headers = "X: 2"))
  expect_equal(cached$headers$x, "2")
  expect_equal(cached$body, resp$body)

  cached <- cache_post_fetch(req, response(304, headers = "X: 3"))
  expect_equal(cached$headers$x, "3")
  expect_equal(cached$body, resp$body)
})

test_that("automatically adds to cache", {
  req <- request("http://example.com") |> req_cache(tempfile())
  expect_true(is.null(cache_get(req)))

  resp <- response(200, headers = 'Etag: "abc"', body = charToRaw("OK"))
  cached <- cache_post_fetch(req, resp)
  expect_false(is.null(cache_get(req)))
  expect_equal(cache_get(req), resp)
})

test_that("cache emits useful debugging info", {
  req <- request("http://example.com") |> req_cache(tempfile(), debug = TRUE)
  resp <- response(
    200,
    headers = "Expires: Wed, 01 Jan 3000 00:00:00 GMT",
    body = charToRaw("abc")
  )

  expect_snapshot({
    "Immutable"
    invisible(cache_pre_fetch(req))
    invisible(cache_post_fetch(req, resp))
    invisible(cache_pre_fetch(req))
  })

  req <- request("http://example.com") |>
    req_cache(tempfile(), debug = TRUE, use_on_error = TRUE)
  resp <- response(200, headers = "X: 1", body = charToRaw("OK"))
  cache_set(req, resp)
  expect_snapshot({
    "freshness check"
    invisible(cache_pre_fetch(req))
    invisible(cache_post_fetch(req, response(304)))
    invisible(cache_post_fetch(req, error_cnd()))
  })
})

# cache -------------------------------------------------------------------

test_that("can get and set from cache", {
  req <- request("http://example.com") |> req_cache(tempfile())
  resp <- response(
    200,
    headers = list(
      Etag = "ABC",
      `content-type` = "application/json",
      other = "header"
    ),
    body = charToRaw(jsonlite::toJSON(list(a = jsonlite::unbox(1))))
  )

  cached_resp <- response(
    304,
    headers = list(
      Etag = "DEF",
      other = "new"
    )
  )

  expect_true(is.null(cache_get(req)))
  cache_set(req, resp)
  expect_false(is.null(cache_get(req)))

  resp_from_cache <- cache_get(req)
  expect_equal(resp_from_cache, resp)

  # Uses new headers if available, otherwise cached headers
  out_headers <- cache_headers(resp_from_cache, cached_resp)
  expect_equal(out_headers$`content-type`, "application/json")
  expect_equal(out_headers$Etag, "DEF")
  expect_equal(out_headers$other, "new")

  # If path is null can leave resp as is
  expect_equal(cache_body(resp_from_cache, NULL), resp$body)
  expect_equal(resp_body_json(resp_from_cache), list(a = 1L))
  # If path is set, need to save to path
  path <- tempfile()
  body <- cache_body(resp_from_cache, path)
  expect_equal(body, new_path(path))
  expect_equal(readLines(path, warn = FALSE), rawToChar(resp$body))
})

test_that("handles responses with files", {
  req <- request("http://example.com") |> req_cache(tempfile())

  path <- local_write_lines("Hi there")
  resp <- response(200, headers = "Etag: ABC", body = new_path(path))
  cache_set(req, resp)

  # File should be copied in cache directory, and response body updated
  body_path <- req_cache_path(req, ".body")
  expect_equal(readLines(body_path), "Hi there")

  resp_from_cache <- cache_get(req)
  expect_equal(resp_from_cache$body, new_path(body_path))

  # If path is null, just leave body as is, since req_body() already
  # papers over the differences
  expect_equal(cache_body(resp_from_cache, NULL), new_path(body_path))

  # If path is not null, copy to desired location, and update body
  path2 <- tempfile()
  body <- cache_body(resp_from_cache, path2)
  expect_equal(readLines(body), "Hi there")
  expect_equal(body, new_path(path2))
})

test_that("corrupt files are ignored", {
  cache_dir <- withr::local_tempdir()
  req <- request("http://example.com") |> req_cache(cache_dir)

  writeLines(letters, req_cache_path(req))
  expect_true(is.null(cache_get(req)))

  saveRDS(1:10, req_cache_path(req))
  expect_false(is.null(cache_get(req)))
})

# pruning -----------------------------------------------------------------

test_that("pruning is throttled", {
  path <- withr::local_tempdir()
  req <- req_cache(request_test(), path = path)

  expect_true(cache_prune_if_needed(req))
  expect_false(cache_prune_if_needed(req))
  expect_true(cache_prune_if_needed(req, threshold = 0))

  the$cache_throttle[[path]] <- Sys.time() - 61
  expect_true(cache_prune_if_needed(req, threshold = 60))
})

test_that("can prune by number", {
  path <- withr::local_tempdir()
  file.create(file.path(path, c("a.rds", "b.rds", "c.rds")))
  Sys.sleep(0.1)
  file.create(file.path(path, c("d.rds")))

  cache_prune(path, list(n = 4, age = Inf, size = Inf), debug = TRUE)
  expect_equal(dir(path), c("a.rds", "b.rds", "c.rds", "d.rds"))

  expect_snapshot(
    cache_prune(path, list(n = 1, age = Inf, size = Inf), debug = TRUE)
  )
  expect_equal(dir(path), c("d.rds"))
})

test_that("can prune by age", {
  path <- withr::local_tempdir()
  file.create(file.path(path, c("a.rds", "b.rds")))
  Sys.setFileTime(file.path(path, "a.rds"), Sys.time() - 60)

  cache_prune(path, list(n = Inf, age = 120, size = Inf), debug = TRUE)
  expect_equal(dir(path), c("a.rds", "b.rds"))

  expect_snapshot({
    cache_prune(path, list(n = Inf, age = 30, size = Inf), debug = TRUE)
  })
  expect_equal(dir(path), "b.rds")
})

test_that("can prune by size", {
  path <- withr::local_tempdir()
  writeChar(paste0(letters, collapse = ""), file.path(path, "a.rds"))
  writeChar(paste0(letters, collapse = ""), file.path(path, "b.rds"))
  Sys.sleep(0.1)
  writeChar(paste0(letters, collapse = ""), file.path(path, "c.rds"))

  cache_prune(path, list(n = Inf, age = Inf, size = 200), debug = TRUE)
  expect_equal(dir(path), c("a.rds", "b.rds", "c.rds"))

  expect_snapshot({
    cache_prune(path, list(n = Inf, age = Inf, size = 50), debug = TRUE)
  })
  expect_equal(dir(path), "c.rds")
})

# headers -----------------------------------------------------------------

test_that("correctly determines if response is cacheable", {
  is_cacheable <- function(...) {
    resp_is_cacheable(response(...))
  }

  expect_equal(is_cacheable(200, headers = "Expires: ABC"), TRUE)
  expect_equal(is_cacheable(200, headers = "Cache-Control: max-age=10"), TRUE)
  expect_equal(is_cacheable(200, headers = "Etag: ABC"), TRUE)
  expect_equal(
    is_cacheable(200, headers = c("Etag: ABC", "Cache-Control: no-store")),
    FALSE
  )
  expect_equal(is_cacheable(200), FALSE)
  expect_equal(is_cacheable(404), FALSE)
  expect_equal(is_cacheable(method = "POST"), FALSE)
})

test_that("can extract cache info with correct types", {
  resp <- response(
    headers = c(
      "Expires: Wed, 01 Jan 2020 00:00:00 GMT",
      "Last-Modified: Wed, 01 Jan 2010 00:00:00 GMT",
      "Etag: \"abc\""
    )
  )
  info <- resp_cache_info(resp)

  expect_equal(info$expires, local_time("2020-01-01"))
  # passed as is back to server, so leave as string
  expect_equal(info$last_modified, "Wed, 01 Jan 2010 00:00:00 GMT")
  # quotes are part of the etag string
  expect_equal(info$etag, '"abc"')
})

test_that("can extract various expiry values", {
  # Prefer Date + max-age
  resp1 <- response(
    headers = c(
      "Date: Wed, 01 Jan 2020 00:00:00 GMT",
      "Cache-Control: max-age=3600",
      "Expiry: Wed, 01 Jan 2020 00:00:00 GMT"
    )
  )
  expect_equal(resp_cache_expires(resp1), local_time("2020-01-01 01:00"))

  # Fall back to Expires
  resp2 <- response(
    headers = c(
      "Expires: Wed, 01 Jan 2020 00:00:00 GMT"
    )
  )
  expect_equal(resp_cache_expires(resp2), local_time("2020-01-01 00:00"))

  # Returns NA if no expiry
  resp2 <- response()
  expect_equal(resp_cache_expires(resp2), NA)
})
