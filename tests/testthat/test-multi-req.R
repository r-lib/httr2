test_that("request and paths must match", {
  req <- request("http://example.com")
  expect_snapshot(req_perform_parallel(req, letters), error = TRUE)
})

test_that("correctly prepares request", {
  reqs <- list(request_test("/post") %>% req_method("POST"))
  expect_no_error(req_perform_parallel(reqs))
})

test_that("requests happen in parallel", {
  # test works best if webfakes has ample threads and keepalive
  skip_on_cran()
  reqs <- list2(
    request_test("/delay/:secs", secs = 0),
    request_test("/delay/:secs", secs = 0.25),
    request_test("/delay/:secs", secs = 0.25),
    request_test("/delay/:secs", secs = 0.25),
    request_test("/delay/:secs", secs = 0.25),
    request_test("/delay/:secs", secs = 0.25),
  )
  time <- system.time(req_perform_parallel(reqs))
  expect_lt(time[[3]], 1)
})

test_that("can perform >128 file uploads in parallel", {
  temp <- withr::local_tempfile(lines = letters)
  req <- request(example_url()) %>% req_body_file(temp)
  reqs <- rep(list(req), 150)

  expect_no_error(req_perform_parallel(reqs, on_error = "continue"))
})

test_that("can download files", {
  reqs <- list(request_test("/json"), request_test("/html"))
  paths <- c(withr::local_tempfile(), withr::local_tempfile())
  resps <- req_perform_parallel(reqs, paths)

  expect_equal(resps[[1]]$body, new_path(paths[[1]]))
  expect_equal(resps[[2]]$body, new_path(paths[[2]]))

  # And check that something was downloaded
  expect_gt(file.size(paths[[1]]), 0)
  expect_gt(file.size(paths[[2]]), 0)
})

test_that("can download 0 byte file", {
  reqs <- list(request_test("/bytes/0"))
  paths <- withr::local_tempfile()
  resps <- req_perform_parallel(reqs, paths = paths)

  expect_equal(file.size(paths[[1]]), 0)
})

test_that("objects are cached", {
  temp <- withr::local_tempdir()
  req <- request_test("etag/:etag", etag = "abcd") %>% req_cache(temp)

  expect_condition(
    resps1 <- req_perform_parallel(list(req)),
    class = "httr2_cache_save"
  )

  expect_condition(
    resps2 <- req_perform_parallel(list(req)),
    class = "httr2_cache_not_modified"
  )
})

test_that("immutable objects retrieved from cache", {
  req <- request("http://example.com") %>% req_cache(tempfile())
  resp <- response(200,
    headers = "Expires: Wed, 01 Jan 3000 00:00:00 GMT",
    body = charToRaw("abc")
  )
  cache_set(req, resp)

  expect_condition(
    resps <- req_perform_parallel(list(req)),
    class = "httr2_cache_cached"
  )
  expect_equal(resps[[1]], resp)
})

test_that("errors by default", {
  reqs <- list2(
    request_test("/status/:status", status = 404),
    request("INVALID")
  )
  expect_snapshot(error = TRUE, {
    req_perform_parallel(reqs[1])
    req_perform_parallel(reqs[2])
  })
})

test_that("both curl and HTTP errors become errors on continue", {
  reqs <- list2(
    request_test("/status/:status", status = 404),
    request("INVALID"),
  )
  out <- req_perform_parallel(reqs, on_error = "continue")
  expect_s3_class(out[[1]], "httr2_http_404")
  expect_s3_class(out[[2]], "httr2_failure")

  # and contain the responses
  expect_equal(out[[1]]$request, reqs[[1]])
  expect_equal(out[[2]]$request, reqs[[2]])
})

test_that("errors can cancel outstanding requests", {
  reqs <- list2(
    request_test("/status/:status", status = 404),
    request_test("/delay/:secs", secs = 2),
  )
  out <- req_perform_parallel(reqs, on_error = "return")
  expect_s3_class(out[[1]], "httr2_http_404")
  expect_null(out[[2]])
})

test_that("req_perform_parallel resspects http_error() error override", {
  reqs <- list2(
    req_error(request_test("/status/:status", status = 404), is_error = ~FALSE),
    req_error(request_test("/status/:status", status = 500), is_error = ~FALSE)
  )
  resps <- req_perform_parallel(reqs)

  expect_equal(resp_status(resps[[1]]), 404)
  expect_equal(resp_status(resps[[2]]), 500)
})


test_that("req_perform_parallel respects http_error() body message", {
  reqs <- list2(
    req_error(request_test("/status/:status", status = 404), body = ~"hello")
  )
  expect_snapshot(req_perform_parallel(reqs), error = TRUE)
})

test_that("multi_req_perform is deprecated", {
  expect_snapshot(multi_req_perform(list()))
})
