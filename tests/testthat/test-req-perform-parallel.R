test_that("request and paths must match", {
  req <- request("http://example.com")
  expect_snapshot(req_perform_parallel(req, letters), error = TRUE)
})

test_that("can perform zero requests", {
  expect_equal(req_perform_parallel(list()), list())
})

test_that("can perform a single request", {
  reqs <- list(request_test("/get"))
  resps <- req_perform_parallel(reqs)
  expect_type(resps, "list")
  expect_length(resps, 1)

  resp <- resps[[1]]
  expect_s3_class(resp, "httr2_response")
  expect_equal(resp$method, "GET")
  expect_equal(resp$url, example_url("/get"))
  expect_equal(resp$status_code, 200)
  expect_s3_class(resp$headers, "httr2_headers")
  expect_type(resp$body, "raw")
  expect_equal(resp$request, reqs[[1]])
})

test_that("requests happen in parallel", {
  # test works best if webfakes has ample threads and keepalive
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
  req <- request(example_url()) |> req_body_file(temp)
  reqs <- rep(list(req), 130)

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
  req <- request_test("etag/:etag", etag = "abcd") |> req_cache(temp)

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
  req <- request("http://example.com") |> req_cache(tempfile())
  resp <- response(
    200,
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
  req <- request_test("/status/:status", status = 404)
  err <- expect_error(req_perform_parallel(list(req)))
  expect_s3_class(err, "httr2_http_404")

  # Wraps and forwards curl errors
  req <- request("INVALID")
  err <- expect_error(req_perform_parallel(list(req)))
  expect_s3_class(err, "httr2_failure")
  expect_s3_class(err$parent, "curl_error_couldnt_resolve_host")
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
    request_test("/delay/:secs", secs = 1),
    request_test("/delay/:secs", secs = 1),
  )
  out <- req_perform_parallel(reqs, on_error = "return", max_active = 1)
  expect_s3_class(out[[1]], "httr2_http_404")
  # second request might succeed or fail depend on the timing, but the
  # third request should definitely fail
  expect_null(out[[3]])
})

test_that("req_perform_parallel resspects http_error() error override", {
  reqs <- list2(
    req_error(
      request_test("/status/:status", status = 404),
      is_error = \(resp) FALSE
    ),
    req_error(
      request_test("/status/:status", status = 500),
      is_error = \(resp) FALSE
    )
  )
  resps <- req_perform_parallel(reqs)

  expect_equal(resp_status(resps[[1]]), 404)
  expect_equal(resp_status(resps[[2]]), 500)
})

test_that("req_perform_parallel respects http_error() body message", {
  reqs <- list2(
    req_error(
      request_test("/status/:status", status = 404),
      body = \(resp) "hello"
    )
  )
  expect_snapshot(req_perform_parallel(reqs), error = TRUE)
})

test_that("requests are throttled", {
  withr::defer(throttle_reset())

  mock_time <- 0
  local_mocked_bindings(
    unix_time = function() mock_time,
    Sys.sleep = function(seconds) mock_time <<- mock_time + seconds
  )

  req <- request_test("/status/:status", status = 200)
  req <- req |> req_throttle(capacity = 1, fill_time_s = 1)
  reqs <- rep(list(req), 5)

  queue <- RequestQueue$new(reqs, progress = FALSE)
  queue$process()
  expect_equal(mock_time, 4)
})


# Tests of lower-level operation -----------------------------------------------

test_that("can retry an OAuth failure", {
  req <- local_app_request(function(req, res) {
    if (res$app$locals$i == 1) {
      res$set_status(401)$set_header(
        "WWW-Authenticate",
        'Bearer realm="example", error="invalid_token"'
      )$send_json(list(status = "failed"), auto_unbox = TRUE)
    } else {
      res$send_json(list(status = "done"), auto_unbox = TRUE)
    }
  })
  req <- req_policies(req, auth_oauth = TRUE)

  reset <- 0
  local_mocked_bindings(
    req_auth_clear_cache = function(...) reset <<- reset + 1
  )

  queue <- RequestQueue$new(list(req), progress = FALSE)
  queue$process()

  expect_equal(reset, 1)
  expect_equal(resp_body_json(queue$resps[[1]]), list(status = "done"))
})

test_that("but multiple failures causes an error", {
  req <- local_app_request(function(req, res) {
    res$set_status(401)$set_header(
      "WWW-Authenticate",
      'Bearer realm="example", error="invalid_token"'
    )$send_json(list(status = "failed"), auto_unbox = TRUE)
  })
  req <- req_policies(req, auth_oauth = TRUE)

  queue <- RequestQueue$new(list(req), progress = FALSE)
  queue$process()
  expect_s3_class(queue$resps[[1]], "httr2_http_401")
})

test_that("can retry a transient error", {
  req <- local_app_request(function(req, res) {
    if (res$app$locals$i == 1) {
      res$set_status(429)$set_header("retry-after", 2)$send_json(
        list(status = "waiting"),
        auto_unbox = TRUE
      )
    } else {
      res$send_json(list(status = "done"), auto_unbox = TRUE)
    }
  })
  req <- req_retry(req, max_tries = 2)

  mock_time <- 1
  local_mocked_bindings(
    unix_time = function() mock_time,
    Sys.sleep = function(seconds) mock_time <<- mock_time + seconds
  )

  queue <- RequestQueue$new(list(req), progress = FALSE)

  # submit the request
  expect_null(queue$process1())
  expect_equal(queue$queue_status, "working")
  expect_equal(queue$n_active, 1)
  expect_equal(queue$n_pending, 0)
  expect_equal(queue$status[[1]], "active")

  # process the response and capture the retry
  expect_null(queue$process1())
  expect_equal(queue$queue_status, "waiting")
  expect_equal(queue$rate_limit_deadline, mock_time + 2)
  expect_equal(queue$n_pending, 1)
  expect_s3_class(queue$resps[[1]], "httr2_http_429")
  expect_equal(resp_body_json(queue$resps[[1]]$resp), list(status = "waiting"))

  # Starting waiting
  expect_null(queue$process1())
  expect_equal(queue$queue_status, "waiting")
  expect_equal(mock_time, 3)

  # Finishing waiting
  expect_null(queue$process1())
  expect_equal(queue$queue_status, "working")
  expect_equal(queue$n_active, 0)
  expect_equal(queue$n_pending, 1)

  # Resubmit
  expect_null(queue$process1())
  expect_equal(queue$queue_status, "working")
  expect_equal(queue$n_active, 1)
  expect_equal(queue$n_pending, 0)

  # Process the response
  expect_null(queue$process1())
  expect_equal(queue$queue_status, "working")
  expect_equal(queue$n_active, 0)
  expect_equal(queue$n_pending, 0)
  expect_s3_class(queue$resps[[1]], "httr2_response")
  expect_equal(resp_body_json(queue$resps[[1]]), list(status = "done"))

  # So we're finally done
  expect_null(queue$process1())
  expect_equal(queue$queue_status, "done")
  expect_false(queue$process1())
})

test_that("throttling is limited by deadline", {
  withr::defer(throttle_reset("test"))

  mock_time <- 0
  local_mocked_bindings(
    unix_time = function() mock_time,
    Sys.sleep = function(seconds) mock_time <<- mock_time + seconds
  )

  req <- request_test("/status/:status", status = 200)
  req <- req_throttle(req, capacity = 1, fill_time_s = 1, realm = "test")
  queue <- RequestQueue$new(list(req), progress = FALSE)

  # Check time only advances by one second, and token is returned to bucket
  local_mocked_bindings(throttle_deadline = function(...) mock_time + 2)
  queue$process1(1)
  expect_equal(queue$queue_status, "waiting")
  queue$process1(1)
  expect_equal(mock_time, 1)
  expect_equal(the$throttle[["test"]]$tokens, 1)

  local_mocked_bindings(throttle_deadline = function(...) mock_time)
  queue$rate_limit_deadline <- mock_time + 2
  expect_equal(mock_time, 1)
  expect_equal(the$throttle[["test"]]$tokens, 1)
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

  resps <- req_perform_parallel(list(req_200, req_404), on_error = "continue")
  expect_equal(resps[[1]], response())
  expect_s3_class(resps[[2]], "httr2_http_404")
})

# otel -----------------------------------------------------------------------

test_that("tracing works as expected", {
  skip_if_not_installed("otelsdk")

  spans <- otelsdk::with_otel_record({
    otel_refresh_tracer("httr2")
    # A request with no URL (which shouldn't create a span).
    try(req_perform_parallel(list(request(""))), silent = TRUE)

    # A request with an HTTP error.
    try(
      req_perform_parallel(list(request_test("/status/:status", status = 404))),
      silent = TRUE
    )

    # A request with a curl error.
    with_mocked_bindings(
      try(req_perform(request("http://127.0.0.1")), silent = TRUE),
      curl_fetch = function(...) abort("Failed to connect")
    )

    # Three regular requests, nested inside a parent span.
    parent <- otel::start_span("parent", tracer = "test")
    otel::with_active_span(parent, {
      resp <- req_perform_parallel(list(
        request_test("/headers"),
        request_test("/headers"),
        request_test("/headers")
      ))
    })
    parent$end()

    # Verify that context propagation works as expected.
    expect_true(
      "traceparent" %in% names(resp_body_json(resp[[1]])[["headers"]])
    )
  })[["traces"]]

  # reset tracer after tests
  otel_refresh_tracer("httr2")

  expect_length(spans, 6L)

  # And for requests with HTTP errors.
  expect_equal(spans[[1]]$status, "error")
  expect_equal(spans[[1]]$description, "Not Found")
  expect_equal(spans[[1]]$attributes$http.response.status_code, 404L)
  expect_equal(spans[[1]]$attributes$error.type, "404")

  # And for spans with curl errors.
  expect_equal(spans[[2]]$status, "error")
  expect_equal(spans[[2]]$attributes$error.type, "rlang_error")

  # We should have attached the curl error as an event.
  expect_length(spans[[2]]$events, 1L)
  expect_equal(spans[[2]]$events[[1]]$name, "exception")

  # Verify that the parent span is the same for parallel requests (that is,
  # they are siblings).
  expect_equal(spans[[3]]$parent, spans[[6]]$span_id)
  expect_equal(spans[[4]]$parent, spans[[6]]$span_id)
  expect_equal(spans[[5]]$parent, spans[[6]]$span_id)
  expect_equal(spans[[6]]$parent, "0000000000000000")
})

# Pool helpers ----------------------------------------------------------------

test_that("wait for deadline waits after pool complete", {
  pool <- curl::new_pool()
  deadline <- unix_time() + 1

  slept <- 0
  local_mocked_bindings(
    unix_time = function() 0,
    Sys.sleep = function(seconds) mock_time <<- slept <<- seconds
  )

  expect_true(pool_wait_for_deadline(pool, deadline = 1))
  expect_equal(slept, 1)
})
