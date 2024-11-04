# promises package test helper
extract_promise <- function(promise, timeout = 30) {
  promise_value <- NULL
  error <- NULL
  done <- FALSE
  promises::then(
    promise,
    onFulfilled = function(value) {
      promise_value <<- value
      done <<- TRUE
    },
    onRejected = function(reason) {
      error <<- reason
      done <<- TRUE
    }
  )

  start <- Sys.time()
  while (!done) {
    if (difftime(Sys.time(), start, units = "secs") > timeout) {
      stop("Waited too long")
    }
    later::run_now()
    Sys.sleep(0.01)
  }

  if (!is.null(error)) {
    cnd_signal(error)
  } else
    promise_value
}

test_that("returns a promise that resolves", {
  p1 <- req_perform_promise(request_test("/delay/:secs", secs = 0.25))
  p2 <- req_perform_promise(request_test("/delay/:secs", secs = 0.25))
  expect_s3_class(p1, "promise")
  expect_s3_class(p2, "promise")
  p1_value <- extract_promise(p1)
  expect_equal(resp_status(p1_value), 200)
  p2_value <- extract_promise(p2)
  expect_equal(resp_status(p2_value), 200)
})

test_that("correctly prepares request", {
  req <- request_test("/post") %>% req_method("POST")
  prom <- req_perform_promise(req)
  expect_no_error(extract_promise(prom))
})

test_that("can promise to download files", {
  req <- request_test("/json")
  path <- withr::local_tempfile()
  p <- req_perform_promise(req, path)
  expect_s3_class(p, "promise")
  p_value <- extract_promise(p)
  expect_equal(p_value$body, new_path(path))

  # And check that something was downloaded
  expect_gt(file.size(path), 0)
})

test_that("promises can retrieve from cache", {
  req <- request("http://example.com") %>% req_cache(tempfile())
  resp <- response(200,
                   headers = "Expires: Wed, 01 Jan 3000 00:00:00 GMT",
                   body = charToRaw("abc")
  )
  cache_set(req, resp)

  p <- req_perform_promise(req)
  expect_s3_class(p, "promise")
  p_value <- extract_promise(p)
  expect_equal(p_value, resp)
})

test_that("both curl and HTTP errors in promises are rejected", {
  expect_error(
    extract_promise(
      req_perform_promise(request_test("/status/:status", status = 404))
    ),
    class = "httr2_http_404"
  )
  expect_error(
    extract_promise(
      req_perform_promise(request("INVALID"))
    ),
    class = "httr2_failure"
  )
  expect_error(
    extract_promise(
      req_perform_promise(request_test("/status/:status", status = 200), pool = "INVALID")
    ),
    'inherits\\(pool, "curl_multi"\\) is not TRUE'
  )
})

test_that("req_perform_promise can use non-default pool", {
  custom_pool <- curl::new_pool()
  p1 <- req_perform_promise(request_test("/delay/:secs", secs = 0.25))
  p2 <- req_perform_promise(request_test("/delay/:secs", secs = 0.25), pool = custom_pool)
  expect_equal(length(curl::multi_list(custom_pool)), 1)
  p1_value <- extract_promise(p1)
  expect_equal(resp_status(p1_value), 200)
  p2_value <- extract_promise(p2)
  expect_equal(resp_status(p2_value), 200)
})
