test_that("successful request returns expected response", {
  req <- request_test()
  resp <- req_perform(req)

  expect_s3_class(resp, "httr2_response")
  expect_equal(resp$method, "GET")
  expect_equal(resp$url, example_url("/get"))
  expect_equal(resp$status_code, 200)
  expect_s3_class(resp$headers, "httr2_headers")
  expect_type(resp$body, "raw")
  expect_equal(resp$request, req)

  expect_type(resp$timing, "double")
  expect_true(all(resp$timing >= 0))
})

test_that("request updates last_response()", {
  req200 <- request_test()
  req404 <- request_test("/404")

  resp <- req_perform(req200)
  expect_equal(last_response(), resp)
  expect_equal(last_request(), req200)

  # even if it errors
  try(req_perform(req404), silent = TRUE)
  expect_equal(last_response()$status_code, 404)
  expect_equal(last_request(), req404)
})

test_that("curl errors become errors", {
  local_mocked_bindings(curl_fetch = function(...) abort("Failed to connect"))

  req <- request("http://127.0.0.1")
  expect_snapshot(req_perform(req), error = TRUE)
  expect_error(req_perform(req), class = "httr2_failure")

  # and captures request
  cnd <- catch_cnd(req_perform(req), classes = "error")
  expect_equal(cnd$request, req)

  # But last_response() is NULL
  expect_null(last_response())
})

test_that("http errors become errors", {
  req <- request_test("/status/:status", status = 404)
  expect_error(req_perform(req), class = "httr2_http_404")
  expect_snapshot(req_perform(req), error = TRUE)

  # and captures request
  cnd <- catch_cnd(req_perform(req), classes = "error")
  expect_equal(cnd$request, req)

  # including transient errors
  req <- request_test("/status/:status", status = 429)
  expect_snapshot(req_perform(req), error = TRUE)

  req_perform(req) |>
    expect_error(class = "httr2_http_429") |>
    expect_no_condition(class = "httr2_sleep")

  # non-standard status codes don't get descriptions
  req <- request_test("/status/:status", status = 599)
  expect_snapshot(req_perform(req), error = TRUE)
})

test_that("can force successful HTTP statuses to error", {
  req <- request_test("/status/:status", status = 200) |>
    req_error(is_error = function(resp) TRUE)

  expect_error(req_perform(req), class = "httr2_http_200")
})

test_that("persistent HTTP errors only get single attempt", {
  req <- request_test("/status/:status", status = 404) |>
    req_retry(max_tries = 5)

  cnd <- req_perform(req) |>
    expect_error(class = "httr2_http_404") |>
    catch_cnd("httr2_fetch")
  expect_equal(cnd$n, 1)
})

test_that("don't retry curl errors by default", {
  req <- request("") |> req_retry(max_tries = 2, failure_realm = "x")
  expect_error(req_perform(req), class = "httr2_failure")

  # But can opt-in to it
  req <- request("") |>
    req_retry(max_tries = 2, retry_on_failure = TRUE, failure_realm = "x")
  cnd <- catch_cnd(req_perform(req), "httr2_retry")
  expect_equal(cnd$tries, 1)
})

test_that("can retry a transient error", {
  req <- local_app_request(function(req, res) {
    if (res$app$locals$i == 1) {
      res$set_status(429)$set_header("retry-after", 0)$send_json(list(
        status = "waiting"
      ))
    } else {
      res$send_json(list(status = "done"))
    }
  })
  req <- req_retry(req, max_tries = 2)

  cnd <- catch_cnd(resp <- req_perform(req), "httr2_retry")
  expect_s3_class(cnd, "httr2_retry")
  expect_equal(cnd$tries, 1)
  expect_equal(cnd$delay, 0)
})


test_that("repeated transient errors still fail", {
  req <- request_test("/status/:status", status = 429) |>
    req_retry(max_tries = 3, backoff = \(i) 0)

  cnd <- req_perform(req) |>
    expect_error(class = "httr2_http_429") |>
    catch_cnd("httr2_fetch")
  expect_equal(cnd$n, 3)
})

test_that("can download 0 byte file", {
  path <- withr::local_tempfile()
  resps <- req_perform(request_test("/bytes/0"), path = path)

  expect_equal(file.size(path[[1]]), 0)
})

test_that("can cache requests with etags", {
  req <- request_test("/etag/:etag", etag = "abc") |> req_cache(tempfile())

  resp1 <- req_perform(req)
  expect_condition(
    expect_condition(
      resp2 <- req_perform(req),
      class = "httr2_cache_not_modified"
    ),
    class = "httr2_cache_save"
  )
})

test_that("can cache requests with paths (cache-control)", {
  req <- request(example_url("/cache/2")) |>
    req_cache(withr::local_tempfile())

  path1 <- withr::local_tempfile()
  expect_condition(
    resp1 <- req |> req_perform(path = path1),
    class = "httr2_cache_save"
  )
  expect_equal(resp1$body[[1]], path1)

  path2 <- withr::local_tempfile()
  expect_condition(
    resp2 <- req |> req_perform(path = path2),
    class = "httr2_cache_cached"
  )
  expect_equal(resp2$body[[1]], path2)

  # Wait until cache expires
  cached_resp <- cache_get(req)
  info <- resp_cache_info(cached_resp)
  Sys.sleep(max(as.double(info$expires - Sys.time()), 0))

  path3 <- withr::local_tempfile()
  expect_condition(
    resp3 <- req |> req_perform(path = path3),
    class = "httr2_cache_save"
  )
  expect_equal(resp3$body[[1]], path3)
})

test_that("can cache requests with paths (if-modified-since)", {
  req <- request(example_url("/cache")) |>
    req_cache(tempfile())

  path1 <- tempfile()
  expect_condition(
    resp1 <- req |> req_perform(path = path1),
    class = "httr2_cache_save"
  )
  expect_equal(resp1$body[[1]], path1)

  path2 <- tempfile()
  expect_condition(
    expect_condition(
      resp2 <- req |> req_perform(path = path2),
      class = "httr2_cache_not_modified"
    ),
    class = "httr2_cache_save"
  )
  expect_equal(resp2$body[[1]], path2)
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

  expect_equal(req_perform(req_200), response())
  expect_error(req_perform(req_404), class = "httr2_http_404")
})

test_that("checks input types", {
  req <- request_test()
  expect_snapshot(error = TRUE, {
    req_perform(req, path = 1)
    req_perform(req, verbosity = 1.5)
    req_perform(req, mock = 7)
  })
})
