test_that("can stream bytes from a connection", {
  resp <- request_test("/stream-bytes/2048") %>% req_perform_connection()
  withr::defer(close(resp))

  expect_s3_class(resp, "httr2_response")
  expect_true(resp_has_body(resp))

  out <- resp_stream_raw(resp, 1)
  expect_length(out, 1024)

  out <- resp_stream_raw(resp, 1)
  expect_length(out, 1024)

  out <- resp_stream_raw(resp, 1)
  expect_length(out, 0)
})

test_that("can determine if a stream is complete (blocking)", {
  resp <- request_test("/stream-bytes/2048") %>% req_perform_connection()
  withr::defer(close(resp))

  expect_false(resp_stream_is_complete(resp))
  expect_length(resp_stream_raw(resp, kb = 2), 2048)
  expect_length(resp_stream_raw(resp, kb = 1), 0)
  expect_true(resp_stream_is_complete(resp))
})

test_that("can determine if a stream is complete (non-blocking)", {
  resp <- request_test("/stream-bytes/2048") %>% req_perform_connection(blocking = FALSE)
  withr::defer(close(resp))

  expect_false(resp_stream_is_complete(resp))
  expect_length(resp_stream_raw(resp, kb = 2), 2048)
  expect_length(resp_stream_raw(resp, kb = 1), 0)
  expect_true(resp_stream_is_complete(resp))
})

test_that("can determine if incomplete data is complete", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("data: 1\n\n")
    res$send_chunk("data: ")
  })

  con <- req %>% req_perform_connection(blocking = TRUE)
  expect_equal(resp_stream_sse(con, 10), list(type = "message", data = "1", id = ""))
  expect_snapshot(expect_equal(resp_stream_sse(con), NULL))
  expect_true(resp_stream_is_complete(con))
  close(con)
})

test_that("can't read from a closed connection", {
  resp <- request_test("/stream-bytes/1024") %>% req_perform_connection()
  close(resp)

  expect_false(resp_has_body(resp))
  expect_snapshot(resp_stream_raw(resp, 1), error = TRUE)

  # and no error if we try to close it again
  expect_no_error(close(resp))
})

test_that("can join lines across multiple reads", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("This is a ")
    Sys.sleep(0.2)
    res$send_chunk("complete sentence.\n")
  })

  # Non-blocking returns NULL until data is ready
  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))

  out <- resp_stream_lines(resp1)
  expect_equal(out, character())
  expect_equal(resp1$cache$push_back, charToRaw("This is a "))

  while (length(out) == 0) {
    Sys.sleep(0.1)
    out <- resp_stream_lines(resp1)
  }
  expect_equal(out, "This is a complete sentence.")
})

test_that("handles line endings of multiple kinds", {
  req <- local_app_request(function(req, res) {
    res$set_header("Content-Type", "text/plain; charset=Shift_JIS")
    res$send_chunk(as.raw(c(0x82, 0xA0, 0x0A)))
    Sys.sleep(0.1)
    res$send_chunk("crlf\r\n")
    Sys.sleep(0.1)
    res$send_chunk("lf\n")
    Sys.sleep(0.1)
    res$send_chunk("cr\r")
    Sys.sleep(0.1)
    res$send_chunk("half line/")
    Sys.sleep(0.1)
    res$send_chunk("other half\n")
    Sys.sleep(0.1)
    res$send_chunk("broken crlf\r")
    Sys.sleep(0.1)
    res$send_chunk("\nanother line\n")
    Sys.sleep(0.1)
    res$send_chunk("eof without line ending")
  })

  resp1 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp1))

  for (expected in c("\u3042", "crlf", "lf", "cr", "half line/other half", "broken crlf", "another line")) {
    rlang::inject(expect_equal(resp_stream_lines(resp1), !!expected))
  }
  expect_warning(
    expect_equal(resp_stream_lines(resp1), "eof without line ending"),
    "incomplete final line"
  )
  expect_identical(resp_stream_lines(resp1), character(0))

  # Same test, but now, non-blocking
  resp2 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp2))

  for (expected in c("\u3042", "crlf", "lf", "cr", "half line/other half", "broken crlf", "another line")) {
    repeat {
      out <- resp_stream_lines(resp2)
      if (length(out) > 0) {
        rlang::inject(expect_equal(out, !!expected))
        break
      }
    }
  }
  expect_warning(
    repeat {
      out <- resp_stream_lines(resp2)
      if (length(out) > 0) {
        expect_equal(out, "eof without line ending")
        break
      }
    },
    "incomplete final line"
  )
})

test_that("streams the specified number of lines", {
  req <- local_app_request(function(req, res) {
    res$send_chunk(paste0(letters[1:5], "\n", collapse = ""))
  })

  resp1 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp1))
  expect_equal(
    resp_stream_lines(resp1, 3),
    c("a", "b", "c")
  )
  expect_equal(
    resp_stream_lines(resp1, 3),
    c("d", "e")
  )
  expect_equal(
    resp_stream_lines(resp1, 3),
    character()
  )

  resp2 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp2))
  Sys.sleep(0.2)
  expect_equal(
    resp_stream_lines(resp2, 3),
    c("a", "b", "c")
  )
  expect_equal(
    resp_stream_lines(resp2, 3),
    c("d", "e")
  )
  expect_equal(
    resp_stream_lines(resp2, 3),
    character()
  )
})

test_that("can feed sse events one at a time", {
  req <- local_app_request(function(req, res) {
    for (i in 1:3) {
      res$send_chunk(sprintf("data: %s\n\n", i))
    }
  })
  resp <- req_perform_connection(req)
  withr::defer(close(resp))

  expect_equal(
    resp_stream_sse(resp),
    list(type = "message", data = "1", id = "")
  )
  expect_equal(
    resp_stream_sse(resp),
    list(type = "message", data = "2", id = "")
  )
  resp_stream_sse(resp)

  expect_equal(resp_stream_sse(resp), NULL)
})

test_that("ignores events with no data", {
  req <- local_app_request(function(req, res) {
    res$send_chunk(": comment\n\n")
    res$send_chunk("data: 1\n\n")
  })
  resp <- req_perform_connection(req)
  withr::defer(close(resp))

  expect_equal(
    resp_stream_sse(resp),
    list(type = "message", data = "1", id = "")
  )
})

test_that("can join sse events across multiple reads", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("data: 1\n")
    Sys.sleep(0.2)
    res$send_chunk("data")
    Sys.sleep(0.2)
    res$send_chunk(": 2\n")
    res$send_chunk("\ndata: 3\n\n")
  })

  # Non-blocking returns NULL until data is ready
  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))

  out <- resp_stream_sse(resp1)
  expect_equal(out, NULL)
  expect_equal(resp1$cache$push_back, charToRaw("data: 1\n"))

  while (is.null(out)) {
    Sys.sleep(0.1)
    out <- resp_stream_sse(resp1)
  }
  expect_equal(out, list(type = "message", data = "1\n2", id = ""))
  expect_equal(resp1$cache$push_back, charToRaw("data: 3\n\n"))
  out <- resp_stream_sse(resp1)
  expect_equal(out, list(type = "message", data = "3", id = ""))

  # Blocking waits for a complete event
  resp2 <- req_perform_connection(req)
  withr::defer(close(resp2))

  out <- resp_stream_sse(resp2)
  expect_equal(out, list(type = "message", data = "1\n2", id = ""))
})

test_that("sse always interprets data as UTF-8", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("data: \xE3\x81\x82\r\n\r\n")
  })

  withr::with_locale(c(LC_CTYPE = "C"), {
    # Non-blocking returns NULL until data is ready
    resp1 <- req_perform_connection(req, blocking = FALSE)
    withr::defer(close(resp1))

    out <- NULL
    while (is.null(out)) {
      Sys.sleep(0.1)
      out <- resp_stream_sse(resp1)
    }

    s <- "\xE3\x81\x82"
    Encoding(s) <- "UTF-8"
    expect_equal(out, list(type = "message", data = s, id = ""))
    expect_equal(Encoding(out$data), "UTF-8")
    expect_equal(resp1$cache$push_back, raw())
  })
})

test_that("streaming size limits enforced", {
  req <- local_app_request(function(req, res) {
    data_size <- 1000
    data <- paste(rep_len("0", data_size), collapse = "")
    res$send_chunk(data)
  })

  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))
  expect_error(
    while (is.null(out)) {
      Sys.sleep(0.1)
      out <- resp_stream_sse(resp1, max_size = 999)
    }
  )

  resp2 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp2))
  expect_error(
    out <- resp_stream_sse(resp2, max_size = 999)
  )

  resp3 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp3))
  expect_error(
    out <- resp_stream_lines(resp3, max_size = 999)
  )
})

test_that("verbosity = 2 streams request bodies", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("line 1\n")
    res$send_chunk("line 2\n")
  })

  stream_all <- function(req, fun, ...) {
    con <- req_perform_connection(req, blocking = TRUE, verbosity = 2)
    on.exit(close(con))
    while (!resp_stream_is_complete(con)) {
      fun(con, ...)
    }
  }
  expect_snapshot(
    {
      stream_all(req, resp_stream_lines, 1)
      stream_all(req, resp_stream_raw, 5 / 1024)
    },
    transform = function(lines) lines[!grepl("^(<-|->)", lines)]
  )
})

test_that("verbosity = 3 shows buffer info", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("line 1\n")
    res$send_chunk("line 2\n")
  })

  expect_output(con <- req_perform_connection(req, blocking = TRUE, verbosity = 3))
  on.exit(close(con))
  expect_snapshot(
    {
      while (!resp_stream_is_complete(con)) {
        resp_stream_lines(con, 1)
      }
    },
    transform = transform_verbose_response
  )
})

test_that("verbosity = 3 shows raw sse events", {
  req <- local_app_request(function(req, res) {
    res$send_chunk(": comment\n\n")
    res$send_chunk("data: 1\n\n")
  })

  expect_output(resp <- req_perform_connection(req, verbosity = 3))
  withr::defer(close(resp))
  expect_snapshot(
    . <- resp_stream_sse(resp),
    transform = transform_verbose_response
  )
})

test_that("has a working find_event_boundary", {
  boundary_test <- function(x, matched, remaining) {
    buffer <- charToRaw(x)
    split_at <- find_event_boundary(buffer)
    result <- if (is.null(split_at)) {
      NULL
    } else {
      split_buffer(buffer, split_at)
    }
    expect_identical(
      result,
      list(matched = charToRaw(matched), remaining = charToRaw(remaining))
    )
  }

  # Basic matches
  boundary_test("\r\r", matched = "\r\r", remaining = "")
  boundary_test("\n\n", matched = "\n\n", remaining = "")
  boundary_test("\r\n\r\n", matched = "\r\n\r\n", remaining = "")
  boundary_test("a\r\r", matched = "a\r\r", remaining = "")
  boundary_test("a\n\n", matched = "a\n\n", remaining = "")
  boundary_test("a\r\n\r\n", matched = "a\r\n\r\n", remaining = "")
  boundary_test("\r\ra", matched = "\r\r", remaining = "a")
  boundary_test("\n\na", matched = "\n\n", remaining = "a")
  boundary_test("\r\n\r\na", matched = "\r\n\r\n", remaining = "a")

  # Matches the first boundary found
  boundary_test("\r\r\r", matched = "\r\r", remaining = "\r")
  boundary_test("\r\r\r\r", matched = "\r\r", remaining = "\r\r")
  boundary_test("\n\n\r\r", matched = "\n\n", remaining = "\r\r")
  boundary_test("\r\r\n\n", matched = "\r\r", remaining = "\n\n")

  # Non-matches
  expect_null(find_event_boundary(charToRaw("\n\r\n\r")))
  expect_null(find_event_boundary(charToRaw("hello\ngoodbye\n")))
  expect_null(find_event_boundary(charToRaw("")))
  expect_null(find_event_boundary(charToRaw("1")))
  expect_null(find_event_boundary(charToRaw("12")))
  expect_null(find_event_boundary(charToRaw("\r\n\r")))
})

# parse_event ----------------------------------------------------------------

test_that("event with no data returns NULL", {
  expect_null(parse_event(""))
  expect_null(parse_event(":comment"))
  expect_null(parse_event("id: 1"))

  expect_equal(parse_event("data: ")$data, "")
  expect_equal(parse_event("data")$data, "")
})

test_that("examples from spec work", {
  event <- parse_event("data: YHOO\ndata: +2\ndata: 10")
  expect_equal(event$type, "message")
  expect_equal(event$data, "YHOO\n+2\n10")
})
