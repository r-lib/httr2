test_that("checks its inputs", {
  req <- request("http://example.com")
  expect_snapshot(error = TRUE, {
    req_perform_sequential(req)
    req_perform_sequential(list(req), letters)
  })
})

test_that("can download files", {
  reqs <- list(request_test("/json"), request_test("/html"))
  paths <- c(withr::local_tempfile(), withr::local_tempfile())
  resps <- req_perform_sequential(reqs, paths)

  expect_equal(resps[[1]]$body, new_path(paths[[1]]))
  expect_equal(resps[[2]]$body, new_path(paths[[2]]))

  # And check that something was downloaded
  expect_gt(file.size(paths[[1]]), 0)
  expect_gt(file.size(paths[[2]]), 0)
})

test_that("on_error = 'return' returns error", {
  reqs <- list2(
    request_test("/status/:status", status = 200),
    request_test("/status/:status", status = 200),
    request_test("/status/:status", status = 404),
    request_test("/status/:status", status = 200)
  )
  out <- req_perform_sequential(reqs, on_error = "return")
  expect_length(out, 4)
  expect_s3_class(out[[3]], "httr2_http_404")
  expect_equal(out[[4]], NULL)
})


test_that("on_error = 'continue' captures both error types", {
  reqs <- list2(
    request_test("/status/:status", status = 404),
    request("INVALID"),
  )
  out <- req_perform_sequential(reqs, on_error = "continue")
  expect_s3_class(out[[1]], "httr2_http_404")
  expect_s3_class(out[[2]], "httr2_failure")
})

test_that("on_error = 'return' returns error", {
  reqs <- list2(
    request_test("/status/:status", status = 200),
    request_test("/status/:status", status = 200),
    request_test("/status/:status", status = 404),
    request_test("/status/:status", status = 200)
  )
  out <- req_perform_sequential(reqs, on_error = "return")
  expect_length(out, 4)
  expect_s3_class(out[[3]], "httr2_http_404")
  expect_equal(out[[4]], NULL)
})

test_that("mocking works", {
  req_200 <- request("https://ok")
  req_404 <- request("https://notok")

  local_mocked_responses(function(req) {
    if (req$url == "https://ok") {
      response()
    } else {
      response(404)
    }
  })

  resps <- req_perform_sequential(list(req_200, req_404), on_error = "continue")
  expect_equal(resps[[1]], response())
  expect_s3_class(resps[[2]], "httr2_http_404")
})
