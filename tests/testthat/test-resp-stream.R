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

test_that("can stream lines from a connection", {
  resp <- request_test("/stream/10") %>% req_perform_connection()
  withr::defer(close(resp))

  out <- resp_stream_lines(resp, 1)
  expect_length(out, 1)

  out <- resp_stream_lines(resp, 10)
  expect_length(out, 9)

  out <- resp_stream_lines(resp, 1)
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
  resp <- request_test("/stream-bytes/2048") %>%
    req_perform_connection(blocking = FALSE)
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
  withr::defer(close(con))

  expect_equal(
    resp_stream_sse(con, 10),
    list(type = "message", data = "1", id = "")
  )
  expect_snapshot(expect_equal(resp_stream_sse(con), NULL))
  expect_true(resp_stream_is_complete(con))
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
  sync <- sync_req("join")
  req <- local_app_request(function(req, res) {
    sync <- req$app$locals$sync_rep("join")

    res$send_chunk("This is a ")
    sync(res$send_chunk("complete sentence.\n"))
  })

  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))

  out <- resp_stream_lines(resp1)
  expect_equal(out, character())
  expect_equal(resp1$cache$buffer$peek_all(), charToRaw("This is a "))

  out <- resp_stream_lines(resp1)
  expect_equal(out, character())

  sync()
  out <- resp_stream_lines(resp1)
  expect_equal(out, "This is a complete sentence.")
})

test_that("handles line endings of multiple kinds", {
  sync <- sync_req("endings")
  req <- local_app_request(function(req, res) {
    sync <- req$app$locals$sync_rep("endings")

    res$set_header("Content-Type", "text/plain; charset=Shift_JIS")
    res$send_chunk(as.raw(c(0x82, 0xA0, 0x0A)))
    sync(res$send_chunk("crlf\r\n"))
    sync(res$send_chunk("lf\n"))
    sync(res$send_chunk("cr\r"))
    sync(res$send_chunk("half line/"))
    sync(res$send_chunk("other half\n"))
    sync(res$send_chunk("broken crlf\r"))
    sync(res$send_chunk("\nanother line\n"))
    sync(res$send_chunk("eof without line ending"))
  })

  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))

  expected_values <- list(
    "\u3042",
    "crlf",
    "lf",
    "cr",
    character(0),
    "half line/other half",
    "broken crlf",
    "another line"
  )

  for (expected in expected_values) {
    rlang::inject(expect_equal(resp_stream_lines(resp1), !!expected))
    sync()
  }
  expect_warning(out <- resp_stream_lines(resp1), "incomplete final line")
  expect_equal(out, "eof without line ending")
  expect_equal(resp_stream_lines(resp1), character(0))

  # Same test, but now, blocking (and without sync)
  req <- local_app_request(function(req, res) {
    res$set_header("Content-Type", "text/plain; charset=Shift_JIS")
    res$send_chunk(as.raw(c(0x82, 0xA0, 0x0A)))
    res$send_chunk("crlf\r\n")
    res$send_chunk("lf\n")
    res$send_chunk("cr\r")
    res$send_chunk("half line/")
    res$send_chunk("other half\n")
    res$send_chunk("broken crlf\r")
    res$send_chunk("\nanother line\n")
    res$send_chunk("eof without line ending")
  })
  resp2 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp2))

  expected_values <- c(
    "\u3042",
    "crlf",
    "lf",
    "cr",
    "half line/other half",
    "broken crlf",
    "another line"
  )

  for (expected in expected_values) {
    rlang::inject(expect_equal(resp_stream_lines(resp2), !!expected))
  }
  expect_warning(out <- resp_stream_lines(resp2), "incomplete final line")
  expect_equal(out, "eof without line ending")
})

test_that("streams the specified number of lines", {
  req <- local_app_request(function(req, res) {
    res$send_chunk(paste0(letters[1:5], "\n", collapse = ""))
  })

  resp1 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp1))
  expect_equal(resp_stream_lines(resp1, 3), c("a", "b", "c"))
  expect_equal(resp_stream_lines(resp1, 3), c("d", "e"))
  expect_equal(resp_stream_lines(resp1, 3), character())

  resp2 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp2))
  expect_equal(resp_stream_lines(resp2, 3), c("a", "b", "c"))
  expect_equal(resp_stream_lines(resp2, 3), c("d", "e"))
  expect_equal(resp_stream_lines(resp2, 3), character())
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
  sync <- sync_req("sse")
  req <- local_app_request(function(req, res) {
    sync <- req$app$locals$sync_rep("sse")

    res$send_chunk("data: 1\n")
    sync(res$send_chunk("data"))
    res$send_chunk(": 2\n")
    sync(res$send_chunk("\ndata: 3\n\n"))
  })

  # Non-blocking returns NULL until data is ready
  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))

  out <- resp_stream_sse(resp1)
  expect_equal(out, NULL)
  expect_equal(resp1$cache$buffer$peek_all(), charToRaw("data: 1\n"))

  sync()
  out <- resp_stream_sse(resp1)
  expect_equal(out, NULL)

  sync()
  out <- resp_stream_sse(resp1)
  expect_equal(out, list(type = "message", data = "1\n2", id = ""))
  expect_equal(resp1$cache$buffer$peek_all(), charToRaw("data: 3\n\n"))

  out <- resp_stream_sse(resp1)
  expect_equal(out, list(type = "message", data = "3", id = ""))

  # # Blocking waits for a complete event
  req <- local_app_request(function(req, res) {
    res$send_chunk("data: 1\n")
    res$send_chunk("data")
    res$send_chunk(": 2\n")
    res$send_chunk("\ndata: 3\n\n")
  })
  resp2 <- req_perform_connection(req)
  withr::defer(close(resp2))

  out <- resp_stream_sse(resp2)
  expect_equal(out, list(type = "message", data = "1\n2", id = ""))
})

test_that("sse always interprets data as UTF-8", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("data: \xE3\x81\x82\r\n\r\n")
  })

  withr::local_locale(LC_CTYPE = "C")
  # Non-blocking returns NULL until data is ready
  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))

  out <- resp_stream_sse(resp1)

  s <- "\xE3\x81\x82"
  Encoding(s) <- "UTF-8"
  expect_equal(out, list(type = "message", data = s, id = ""))
  expect_equal(Encoding(out$data), "UTF-8")
  expect_equal(resp1$cache$buffer$peek_all(), raw())
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
    out <- resp_stream_sse(resp1, max_size = 999),
    class = "httr2_streaming_error"
  )

  resp2 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp2))
  expect_error(
    out <- resp_stream_sse(resp2, max_size = 999),
    class = "httr2_streaming_error"
  )
})

test_that("verbosity = 2 streams request bodies", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("line 1\n")
    res$send_chunk("line 2\n")
  })

  stream_all <- function(req, fun, ...) {
    con <- req_perform_connection(req, blocking = TRUE, verbosity = 2)
    withr::defer(close(con))
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

  expect_output(
    con <- req_perform_connection(req, blocking = TRUE, verbosity = 3)
  )
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
    if (is.null(matched)) {
      exp <- list(matched = NULL, remaining = NULL)
    } else {
      exp <- list(
        matched = charToRaw(matched),
        remaining = charToRaw(remaining)
      )
    }

    buffer <- RingBuffer$new()
    buffer$push(charToRaw(x))

    loc <- find_event_boundary(buffer)
    if (is.null(loc)) {
      act <- list(matched = NULL, remaining = NULL)
    } else {
      act <- list(matched = buffer$pop(loc), remaining = buffer$pop())
    }

    expect_equal(act, exp)
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
  boundary_test("\n\r\n\r", matched = NULL)
  boundary_test("hello\ngoodbye\n", matched = NULL)
  boundary_test("", matched = NULL)
  boundary_test("1", matched = NULL)
  boundary_test("12", matched = NULL)
  boundary_test("\r\n\r", matched = NULL)
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
