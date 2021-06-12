test_that("requests happen in parallel", {
  reqs <- list2(
    request_test("/delay/:secs", secs = 0.5),
    request_test("/delay/:secs", secs = 0.5),
    request_test("/delay/:secs", secs = 0.5),
    request_test("/delay/:secs", secs = 0.5),
    request_test("/delay/:secs", secs = 0.5),
  )
  time <- system.time(multi_req_fetch(reqs))
  expect_lt(time[[3]], 1)
})

test_that("both curl and HTTP errors become errors", {
  reqs <- list2(
    request_test("/status/:status", status = 404),
    request("INVALID"),
  )
  out <- multi_req_fetch(reqs)
  expect_s3_class(out[[1]], "httr2_http_404")
  expect_s3_class(out[[2]], "httr2_failed")
})

test_that("errors can cancel outstanding requests", {
  reqs <- list2(
    request_test("/status/:status", status = 404),
    request_test("/delay/:secs", secs = 2),
  )
  out <- multi_req_fetch(reqs, cancel_on_error = TRUE)
  expect_s3_class(out[[1]], "httr2_http_404")
  expect_s3_class(out[[2]], "httr2_cancelled")

  reqs <- list2(
    request("blah://INVALID"),
    request_test("/delay/:secs", secs = 2),
  )
  out <- multi_req_fetch(reqs, cancel_on_error = TRUE)
  expect_s3_class(out[[1]], "httr2_failed")
  expect_s3_class(out[[2]], "httr2_cancelled")
})
