test_that("request and paths must match", {
  req <- request("http://example.com")
  expect_snapshot(req_perform_parallel(req, letters), error = TRUE)
})

test_that("requests happen in parallel", {
  # GHA MacOS builder seems to be very slow
  skip_if(
    isTRUE(as.logical(Sys.getenv("CI", "false"))) &&
    Sys.info()[["sysname"]] == "Darwin"
  )

  reqs <- list2(
    request_test("/delay/:secs", secs = 0.25),
    request_test("/delay/:secs", secs = 0.25),
    request_test("/delay/:secs", secs = 0.25),
    request_test("/delay/:secs", secs = 0.25),
    request_test("/delay/:secs", secs = 0.25),
  )
  time <- system.time(req_perform_parallel(reqs))
  expect_lt(time[[3]], 1)
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

test_that("both curl and HTTP errors become errors", {
  reqs <- list2(
    request_test("/status/:status", status = 404),
    request("INVALID"),
  )
  out <- req_perform_parallel(reqs)
  expect_s3_class(out[[1]], "httr2_http_404")
  expect_s3_class(out[[2]], "httr2_failure")
})

test_that("errors can cancel outstanding requests", {
  reqs <- list2(
    request_test("/status/:status", status = 404),
    request_test("/delay/:secs", secs = 2),
  )
  out <- req_perform_parallel(reqs, cancel_on_error = TRUE)
  expect_s3_class(out[[1]], "httr2_http_404")
  expect_s3_class(out[[2]], "httr2_cancelled")

  reqs <- list2(
    request("blah://INVALID"),
    request_test("/delay/:secs", secs = 2),
  )
  out <- req_perform_parallel(reqs, cancel_on_error = TRUE)
  expect_s3_class(out[[1]], "httr2_failure")
  expect_s3_class(out[[2]], "httr2_cancelled")
})

test_that("multi_req_perform is deprecated", {
  expect_snapshot(multi_req_perform(list()))
})
