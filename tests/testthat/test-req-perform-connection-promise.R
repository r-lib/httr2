test_that("checks its inputs", {
  req <- request_test()

  expect_snapshot(error = TRUE, {
    req_perform_connection_promise(1)
    req_perform_connection_promise(req, verbosity = "INVALID")
  })
})

test_that("event loop isn't blocked while waiting for headers (#921)", {
  req <- local_app_request(function(req, res) {
    Sys.sleep(1)
    res$send_json(list(ok = TRUE), auto_unbox = TRUE)
  })

  start <- Sys.time()
  fired <- NULL
  later::later(function() fired <<- Sys.time(), 0.1)
  expect_condition(
    p <- req_perform_connection_promise(req),
    class = "httr2_perform_connection"
  )
  expect_s3_class(p, "promise")
  resp <- extract_promise(p)
  withr::defer(close(resp))
  resolved <- Sys.time()

  expect_lt(as.double(fired - start, units = "secs"), 0.5)
  expect_gte(as.double(resolved - start, units = "secs"), 1)
  expect_equal(resp_status(resp), 200)
  expect_s3_class(resp$body, "StreamingBody")
  expect_equal(resp_body_json(resp), list(ok = TRUE))
})

test_that("resolves once the headers are received", {
  req <- local_app_request(function(req, res) {
    if (is.null(res$locals$sent)) {
      res$locals$sent <- TRUE
      res$set_header("Content-Length", 5)$set_type("text/plain")
      res$write("")
      res$delay(1)
    } else {
      res$write("hello")
      res$send("")
    }
  })

  resp <- extract_promise(req_perform_connection_promise(req))
  withr::defer(close(resp))
  expect_equal(resp_status(resp), 200)
  expect_equal(resp_header(resp, "Content-Length"), "5")
  expect_equal(resp_stream_raw(resp), raw())

  expect_equal(resp_body_string(resp), "hello")
})

test_that("can stream lines and server-sent events", {
  resp1 <- extract_promise(
    req_perform_connection_promise(request_test("/stream/:n", n = 5))
  )
  withr::defer(close(resp1))
  lines <- character()
  while (!resp_stream_is_complete(resp1)) {
    lines <- c(lines, resp_stream_lines(resp1))
  }
  expect_length(lines, 5)

  resp2 <- extract_promise(
    req_perform_connection_promise(stream_app_chunks(
      "data: 1\n\n",
      "data: 2\n\n"
    ))
  )
  withr::defer(close(resp2))
  events <- list()
  while (!resp_stream_is_complete(resp2)) {
    event <- resp_stream_sse(resp2)
    if (!is.null(event)) events[[length(events) + 1]] <- event$data
  }
  expect_equal(events, list("1", "2"))
})

test_that("can stream multiple connections concurrently", {
  p1 <- req_perform_connection_promise(request_test("/stream/:n", n = 3))
  p2 <- req_perform_connection_promise(request_test("/stream/:n", n = 4))

  resps <- extract_promise(promises::promise_all(p1, p2))
  resp1 <- resps[[1]]
  resp2 <- resps[[2]]
  withr::defer(close(resp1))
  withr::defer(close(resp2))

  lines1 <- character()
  lines2 <- character()
  while (!resp_stream_is_complete(resp1) || !resp_stream_is_complete(resp2)) {
    if (!resp_stream_is_complete(resp1)) {
      lines1 <- c(lines1, resp_stream_lines(resp1))
    }
    if (!resp_stream_is_complete(resp2)) {
      lines2 <- c(lines2, resp_stream_lines(resp2))
    }
  }

  expect_length(lines1, 3)
  expect_length(lines2, 4)
})

test_that("works in a temporary event loop", {
  resp <- later::with_temp_loop({
    extract_promise(req_perform_connection_promise(request_test("/get")))
  })
  withr::defer(close(resp))
  expect_equal(resp_status(resp), 200)
})

test_that("reads don't block", {
  sync <- sync_req("pull")
  resp <- extract_promise(
    req_perform_connection_promise(stream_app_request("/pull"))
  )
  withr::defer(close(resp))

  expect_equal(resp_stream_lines(resp), character())
  expect_equal(resp_stream_is_complete(resp), FALSE)

  sync(resp)
  expect_equal(resp_stream_lines(resp), "This is a complete sentence.")
})

test_that("can wait for data with get_fdset()", {
  req <- request_test("/drip?duration=0.5&numbytes=5")
  resp <- extract_promise(req_perform_connection_promise(req))
  withr::defer(close(resp))

  bytes <- raw()
  n_reads <- integer()
  while (!resp_stream_is_complete(resp)) {
    bytes <- c(bytes, resp_stream_raw(resp))
    if (resp_stream_is_complete(resp)) {
      break
    }
    fds <- resp$body$get_fdset()
    n_reads <- c(n_reads, length(fds$reads))
    wait <- promises::promise(function(resolve, reject) {
      later::later_fd(
        resolve,
        fds$reads,
        fds$writes,
        fds$exceptions,
        fds$timeout / 1000
      )
    })
    extract_promise(wait, timeout = 5)
  }
  expect_length(bytes, 5)
  expect_gt(max(n_reads), 0)
})

test_that("handles empty bodies and redirects", {
  resp <- extract_promise(
    req_perform_connection_promise(request_test("/status/:s", s = 204))
  )
  expect_equal(resp_status(resp), 204)
  expect_equal(resp_stream_is_complete(resp), TRUE)
  expect_equal(resp_stream_raw(resp), raw())
  close(resp)

  resp2 <- extract_promise(
    req_perform_connection_promise(request_test("/redirect/:n", n = 2))
  )
  withr::defer(close(resp2))
  expect_equal(resp_url_path(resp2), "/get")
})

test_that("resolves non-final-looking statuses once body arrives", {
  req <- local_app_request(function(req, res) {
    res$set_status(401L)$set_type("text/plain")$send("unauthorized")
  }) |>
    req_error(is_error = \(resp) FALSE)

  resp <- extract_promise(req_perform_connection_promise(req))
  withr::defer(close(resp))
  expect_equal(resp_status(resp), 401)
  expect_equal(resp_body_string(resp), "unauthorized")
})

test_that("HTTP errors reject with the complete body", {
  req <- local_app_request(function(req, res) {
    if (is.null(res$locals$sent)) {
      res$locals$sent <- TRUE
      res$set_status(404L)$set_type("application/json")
      res$set_header("Content-Length", 33)
      res$write('{"status":404,')
      res$delay(0.1)
    } else {
      res$write('"detail":"missing"}')
      res$send("")
    }
  }) |>
    req_error(body = \(resp) resp_body_json(resp)$detail)

  cnd <- expect_error(
    extract_promise(req_perform_connection_promise(req)),
    class = "httr2_http_404"
  )
  expect_equal(
    resp_body_json(cnd$resp),
    list(status = 404, detail = "missing")
  )
  expect_equal(
    resp_body_json(last_response()),
    list(status = 404, detail = "missing")
  )
  expect_match(conditionMessage(cnd), "missing")
})

test_that("errors in req_error() callbacks reject and clean up", {
  done <- 0L
  req <- request_test("/drip?duration=5&numbytes=5") |>
    req_policies(done = function() done <<- done + 1L) |>
    req_error(is_error = \(resp) {
      cli::cli_abort("bad predicate", class = "test_predicate_error")
    })

  expect_error(
    extract_promise(req_perform_connection_promise(req)),
    class = "test_predicate_error"
  )
  expect_equal(done, 1L)

  done2 <- 0L
  req2 <- request_test("/status/:s", s = 404) |>
    req_policies(done = function() done2 <<- done2 + 1L) |>
    req_error(body = \(resp) {
      cli::cli_abort("bad body", class = "test_body_error")
    })

  expect_error(
    extract_promise(req_perform_connection_promise(req2)),
    class = "test_body_error"
  )
  expect_equal(done2, 1L)
})

test_that("curl errors reject", {
  req <- request(paste0("http://127.0.0.1:", curl::find_port()))
  cnd <- expect_error(
    extract_promise(req_perform_connection_promise(req)),
    class = "httr2_failure"
  )
  expect_equal(cnd$request, req_policies(req, connection = TRUE))

  local_curl_error()
  req2 <- request("http://127.0.0.1")
  cnd2 <- expect_error(
    extract_promise(req_perform_connection_promise(req2)),
    class = "httr2_failure"
  )
  expect_equal(cnd2$request, req_policies(req2, connection = TRUE))
})

test_that("failures after resolving are surfaced when reading", {
  req <- local_app_request(function(req, res) {
    res$set_header("Content-Length", 100)$set_type("text/plain")
    res$send("short")
  })

  resp <- extract_promise(req_perform_connection_promise(req))
  withr::defer(close(resp))

  out <- raw()
  expect_error(
    while (!resp_stream_is_complete(resp)) {
      out <- c(out, resp_stream_raw(resp))
    },
    class = "curl_error_partial_file"
  )
  expect_equal(rawToChar(out), "short")
})

test_that("close() closes the streaming body", {
  req <- request_test("/drip?duration=5&numbytes=5")
  resp <- extract_promise(req_perform_connection_promise(req))

  close(resp)
  expect_equal(resp$body$is_open(), FALSE)
  expect_snapshot(resp_stream_raw(resp), error = TRUE)
})

test_that("mocking works", {
  local_mocked_responses(function(req) {
    expect_equal(req$policies$connection, TRUE)
    if (req$url == "https://ok") {
      response(body = StreamingBody$new(rawConnection(charToRaw("a\nb\n"))))
    } else {
      response(404)
    }
  })

  resp <- extract_promise(
    req_perform_connection_promise(request("https://ok"))
  )
  expect_equal(resp_stream_lines(resp, 2), c("a", "b"))
  close(resp)

  expect_error(
    extract_promise(req_perform_connection_promise(request("https://notok"))),
    class = "httr2_http_404"
  )
})

# otel -----------------------------------------------------------------------

test_that("tracing works as expected", {
  skip_if_not_installed("otelsdk")
  skip_on_os("windows")

  spans <- with_otel_record({
    # A request with no URL (which shouldn't create a span).
    try(
      extract_promise(req_perform_connection_promise(request(""))),
      silent = TRUE
    )

    # A request with an HTTP error.
    p <- req_perform_connection_promise(request_test(
      "/status/:status",
      status = 404
    ))
    try(extract_promise(p), silent = TRUE)

    # A request with a curl error.
    local({
      local_curl_error()
      p <- req_perform_connection_promise(request("http://127.0.0.1"))
      try(extract_promise(p), silent = TRUE)
    })

    # A request whose is_error callback throws (should still close its span).
    p_err <- request_test("/status/:status", status = 204) |>
      req_error(is_error = \(resp) stop("boom")) |>
      req_perform_connection_promise()
    try(extract_promise(p_err), silent = TRUE)

    # A request with no parent context.
    p <- req_perform_connection_promise(request_test("/headers"))

    # A request nested inside a parent span.
    parent <- otel::start_span("parent", tracer = "test")
    otel::with_active_span(parent, {
      child <- req_perform_connection_promise(request_test("/get"))
      # Resolve the earlier request with a different active span; this should
      # not affect its parent.
      resp <- extract_promise(p)
    })
    child_resp <- extract_promise(child)
    parent$end()

    # Verify that context propagation works as expected.
    expect_in("traceparent", names(resp_body_json(resp)[["headers"]]))
    close(resp)
    close(child_resp)
  })[["traces"]]

  expect_length(spans, 6L)

  # HTTP error span.
  expect_equal(spans[[1]]$status, "error")
  expect_equal(spans[[1]]$description, "Not Found")
  expect_equal(spans[[1]]$attributes$http.response.status_code, 404L)
  expect_equal(spans[[1]]$attributes$error.type, "404")

  # Curl error span.
  expect_equal(spans[[2]]$status, "error")
  expect_equal(spans[[2]]$attributes$error.type, "curl_error_couldnt_connect")
  expect_length(spans[[2]]$events, 1L)
  expect_equal(spans[[2]]$events[[1]]$name, "exception")

  # Callback error span closed cleanly.
  expect_equal(spans[[3]]$status, "unset")

  # Parent context captured at submission time, not resolution time.
  # Concurrent requests can finish in either order, so identify them by URL.
  urls <- map_chr(spans[4:5], \(span) span$attributes$url.full)
  no_parent_span <- spans[4:5][[which(endsWith(urls, "/headers"))]]
  child_span <- spans[4:5][[which(endsWith(urls, "/get"))]]
  expect_equal(no_parent_span$parent, spans[[6]]$parent)
  expect_equal(child_span$parent, spans[[6]]$span_id)
})
