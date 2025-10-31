test_that("checks its inputs", {
  req <- request_test("/status/:status", status = 200)

  expect_snapshot(error = TRUE, {
    req_perform_promise(1)
    req_perform_promise(req, path = 1)
    req_perform_promise(req, pool = "INVALID")
    req_perform_promise(req, verbosity = "INVALID")
  })
})

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
  req <- request_test("/post") |> req_method("POST")
  prom <- req_perform_promise(req)
  expect_no_error(extract_promise(prom))
})

test_that("correctly prepares request", {
  req <- request_test("/get")
  expect_snapshot(
    . <- extract_promise(req_perform_promise(req, verbosity = 1)),
    transform = function(x) {
      gsub(
        "(Date|Host|User-Agent|ETag|Content-Length|Accept-Encoding): .*",
        "\\1: <variable>",
        x
      )
    }
  )
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
  req <- request("http://example.com") |> req_cache(tempfile())
  resp <- response(
    200,
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
})

test_that("req_perform_promise doesn't leave behind poller", {
  skip_if_not(
    later::loop_empty(),
    "later::global_loop not empty when test started"
  )
  p <- req_perform_promise(request_test("/delay/:secs", secs = 0.25))
  # Before promise is resolved, there should be an operation in our later loop
  expect_false(later::loop_empty())
  p_value <- extract_promise(p)
  # But now that that our promise is resolved, we shouldn't still be polling the pool
  expect_true(later::loop_empty())
})


test_that("req_perform_promise can use non-default pool", {
  custom_pool <- curl::new_pool()
  p1 <- req_perform_promise(request_test("/delay/:secs", secs = 0.25))
  p2 <- req_perform_promise(
    request_test("/delay/:secs", secs = 0.25),
    pool = custom_pool
  )
  expect_equal(length(curl::multi_list(custom_pool)), 1)
  p1_value <- extract_promise(p1)
  expect_equal(resp_status(p1_value), 200)
  p2_value <- extract_promise(p2)
  expect_equal(resp_status(p2_value), 200)
})

test_that("req_perform_promise uses the default loop", {
  # The main reason for temp loops is to allow an asynchronous operation to be
  # created, waited on, and resolved/rejected inside of a synchronous function,
  # all without affecting any asynchronous operations that existed before the
  # temp loop was created.

  # This can't proceed within the temp loop
  p1 <- req_perform_promise(request_test("/delay/:secs", secs = 0.25))

  later::with_temp_loop({
    # You can create an async response with explicit pool=NULL, but it can't
    # proceed until the temp loop is over
    p2 <- req_perform_promise(request_test("/get"), pool = NULL)

    # You can create an async response with explicit pool=pool, and it can
    # proceed as long as that pool was first used inside of the temp loop
    p3 <- req_perform_promise(request_test("/get"), pool = curl::new_pool())

    # You can't create an async response in the temp loop without explicitly
    # specifying a pool
    expect_snapshot(
      p4 <- req_perform_promise(request_test("/get")),
      error = TRUE
    )

    # Like I said, you can create this, but it won't work until we get back
    # outside the temp loop
    expect_null(extract_promise(p2, timeout = 1))

    # This works fine inside the temp loop, because its pool was first used
    # inside
    expect_equal(resp_status(extract_promise(p3, timeout = 1)), 200)
  })

  # These work fine now that we're back outside the temp loop
  expect_equal(resp_status(extract_promise(p1, timeout = 1)), 200)
  expect_equal(resp_status(extract_promise(p2, timeout = 1)), 200)
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
  expect_equal(
    extract_promise(req_perform_promise(req_200)),
    response()
  )
  expect_error(
    extract_promise(req_perform_promise(req_404)),
    class = "httr2_http_404"
  )
})

# otel -----------------------------------------------------------------------

test_that("tracing works as expected", {
  skip_if_not_installed("otelsdk")
  skip_on_os("windows")

  spans <- otelsdk::with_otel_record({
    otel_refresh_tracer("httr2")
    # A request with no URL (which shouldn't create a span).
    try(req_perform_promise(request("")), silent = TRUE)

    # A request with an HTTP error.
    p <- req_perform_promise(request_test("/status/:status", status = 404))
    try(extract_promise(p), silent = TRUE)

    # A request with a curl error.
    with_mocked_bindings(
      {
        p <- req_perform_promise(request("http://127.0.0.1"))
        try(extract_promise(p), silent = TRUE)
      },
      curl_fetch = function(...) abort("Failed to connect")
    )

    # A request with no parent context.
    p <- req_perform_promise(request_test("/headers"))

    # A request nested inside a parent span.
    parent <- otel::start_span("parent", tracer = "test")
    otel::with_active_span(parent, {
      child <- req_perform_promise(request_test())
      # Resolve the earlier request with a different session; this should not
      # affect its parent.
      resp <- extract_promise(p)
    })
    extract_promise(child)
    parent$end()

    # Verify that context propagation works as expected.
    expect_true(
      "traceparent" %in% names(resp_body_json(resp)[["headers"]])
    )
  })[["traces"]]
  # reset tracer after tests
  otel_refresh_tracer("httr2")

  expect_length(spans, 5L)

  # And for requests with HTTP errors.
  expect_equal(spans[[1]]$status, "error")
  expect_equal(spans[[1]]$description, "Not Found")
  expect_equal(spans[[1]]$attributes$http.response.status_code, 404L)
  expect_equal(spans[[1]]$attributes$error.type, "404")

  # And for spans with curl errors.
  expect_equal(spans[[2]]$status, "error")
  expect_equal(spans[[2]]$attributes$error.type, "curl_error_couldnt_connect")

  # We should have attached the curl error as an event.
  expect_length(spans[[2]]$events, 1L)
  expect_equal(spans[[2]]$events[[1]]$name, "exception")

  # Verify that the spans for requests resolved later still have the parent
  # context in which they were submitted.
  expect_equal(spans[[3]]$parent, "0000000000000000")
  expect_equal(spans[[4]]$parent, spans[[5]]$span_id)
  expect_equal(spans[[5]]$parent, "0000000000000000")
})
