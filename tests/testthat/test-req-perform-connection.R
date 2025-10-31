test_that("validates inputs", {
  expect_snapshot(error = TRUE, {
    req_perform_connection(1)
    req_perform_connection(request_test(), 1)
  })
})

test_that("correctly prepares request", {
  req <- request_test("/post") |> req_method("POST")
  expect_no_error(resp <- req_perform_connection(req))
  close(resp)
})

test_that("can read all data from a connection", {
  resp <- request_test("/stream-bytes/2048") |> req_perform_connection()
  withr::defer(close(resp))

  out <- resp_body_raw(resp)
  expect_length(out, 2048)
  expect_false(resp_has_body(resp))
})

test_that("reads body on error", {
  req <- local_app_request(function(req, res) {
    res$set_status(404L)$send_json(list(status = 404), auto_unbox = TRUE)
  })

  expect_error(req_perform_connection(req), class = "httr2_http_404")
  resp <- last_response()
  expect_equal(resp_body_json(resp), list(status = 404))
})

test_that("can retry a transient error", {
  req <- local_app_request(function(req, res) {
    if (res$app$locals$i == 1) {
      res$set_status(429)$set_header("retry-after", 0)$send_json(
        list(status = "waiting"),
        auto_unbox = TRUE
      )
    } else {
      res$send_json(list(status = "done"), auto_unbox = TRUE)
    }
  })
  req <- req_retry(req, max_tries = 2)

  cnd <- expect_condition(
    resp <- req_perform_connection(req),
    class = "httr2_retry"
  )
  expect_s3_class(cnd, "httr2_retry")
  expect_equal(cnd$tries, 1)
  expect_equal(cnd$delay, 0)

  expect_equal(last_response(), resp)
  expect_equal(resp_body_json(resp), list(status = "done"))
})

test_that("curl errors become errors", {
  local_mocked_bindings(open = function(...) abort("Failed to connect"))

  req <- request("http://127.0.0.1")
  expect_snapshot(req_perform_connection(req), error = TRUE)
  expect_error(req_perform_connection(req), class = "httr2_failure")

  # and captures request
  cnd <- catch_cnd(req_perform_connection(req), classes = "error")
  expect_equal(cnd$request, req_policies(req, connection = TRUE))

  # But last_response() is NULL
  expect_null(last_response())
})

test_that("mocking works", {
  req_200 <- request("https://ok")
  req_404 <- request("https://notok")

  local_mocked_responses(function(req) {
    expect_equal(req$policies$connection, TRUE)
    if (req$url == "https://ok") {
      conn <- rawConnection(charToRaw("a\nb\n"))
      response(body = StreamingBody$new(conn))
    } else {
      response(404)
    }
  })

  resp <- req_perform_connection(req_200)
  expect_equal(resp_stream_lines(resp), "a")
  expect_equal(resp_stream_lines(resp), "b")
  close(resp)

  expect_error(req_perform_connection(req_404), class = "httr2_http_404")
})


# StreamingBody --------------------------------------------------------------

test_that("validates its input", {
  expect_snapshot(error = TRUE, {
    StreamingBody$new(1)
  })
})

test_that("can access fdset", {
  skip_on_cran()

  con <- curl::curl(example_url('/drip'), open = 'rb')
  on.exit(close(con))

  body <- StreamingBody$new(con)
  expect_length(body$get_fdset()$reads, 1)
})

# otel -----------------------------------------------------------------------

test_that("tracing works as expected", {
  skip_if_not_installed("otelsdk")
  skip_on_os("windows")

  spans <- otelsdk::with_otel_record({
    otel_refresh_tracer("httr2")
    # A request with no URL (which shouldn't create a span).
    try(req_perform_connection(request("")), silent = TRUE)

    # A regular request.
    resp <- req_perform_connection(request_test("/headers"))

    # Verify that context propagation works as expected.
    expect_true("traceparent" %in% names(resp_body_json(resp)[["headers"]]))
    close(resp)

    # A request with an HTTP error.
    try(
      req_perform_connection(request_test("/status/:status", status = 404)),
      silent = TRUE
    )

    # A request with basic credentials that we should redact.
    parsed <- url_parse(example_url())
    parsed$username <- "user"
    parsed$password <- "secret"
    resp <- req_perform_connection(request(url_build(parsed)))
    close(resp)

    # A request with a curl error.
    with_mocked_bindings(
      try(req_perform_connection(request("http://127.0.0.1")), silent = TRUE),
      curl_fetch = function(...) abort("Failed to connect")
    )

    # A request that triggers retries, generating three individual spans.
    request_test("/status/:status", status = 429) |>
      req_retry(max_tries = 3, backoff = ~0) |>
      req_perform_connection() |>
      try(silent = TRUE)
  })[["traces"]]

  # reset tracer after tests
  otel_refresh_tracer("httr2")

  expect_length(spans, 7L)

  # Validate the span for regular requests.
  expect_equal(spans[[1]]$status, "ok")
  expect_named(
    spans[[1]]$attributes,
    c(
      "http.response.status_code",
      "user_agent.original",
      "url.full",
      "server.address",
      "server.port",
      "http.request.method"
    ),
    ignore.order = TRUE
  )
  expect_equal(spans[[1]]$attributes$http.request.method, "GET")
  expect_equal(spans[[1]]$attributes$http.response.status_code, 200L)
  expect_equal(spans[[1]]$attributes$server.address, "127.0.0.1")
  expect_match(spans[[1]]$attributes$user_agent.original, "^httr2/")

  # And for requests with HTTP errors.
  expect_equal(spans[[2]]$status, "error")
  expect_equal(spans[[2]]$description, "Not Found")
  expect_equal(spans[[2]]$attributes$http.response.status_code, 404L)
  expect_equal(spans[[2]]$attributes$error.type, "404")

  # And for spans with redacted credentials.
  expect_match(
    spans[[3]]$attributes$url.full,
    regexp = "http://REDACTED:REDACTED@127.0.0.1:[0-9]+/",
  )

  # And for spans with curl errors.
  expect_equal(spans[[4]]$status, "error")
  expect_equal(spans[[4]]$attributes$error.type, "simpleError")

  # We should have attached the curl error as an event.
  expect_length(spans[[4]]$events, 1L)
  expect_equal(spans[[4]]$events[[1]]$name, "exception")

  # For spans with retries, we expect the parent context to be the same for
  # each span. (In this case, there is no parent span, so it should be empty.)
  # It is important that they not be children of one another.
  expect_equal(spans[[5]]$parent, "0000000000000000")
  expect_equal(spans[[6]]$parent, "0000000000000000")
  expect_equal(spans[[7]]$parent, "0000000000000000")
})
