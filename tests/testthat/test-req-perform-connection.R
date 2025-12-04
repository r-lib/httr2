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

test_that("correclty reports curl error with retries (#817)", {
  local_mocked_bindings(open = function(...) abort("Failed to connect"))

  req <- request("http://127.0.0.1") |>
    req_retry(max_tries = 2, retry_on_failure = TRUE, backoff = \(i) 0)

  expect_snapshot(req_perform_connection(req), error = TRUE)
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
