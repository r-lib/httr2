test_that("can join lines across multiple reads", {
  sync <- sync_req("join")
  req <- local_app_request(function(req, res) {
    sync <- req$app$locals$sync_rep("join")

    res$send_chunk("This is a ")
    sync(res$send_chunk("complete sentence.\n"))
  })

  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))
  wait_for_http_data(resp1)

  out <- resp_stream_lines(resp1)
  expect_equal(out, character())
  expect_equal(resp1$cache$push_back, charToRaw("This is a "))

  out <- resp_stream_lines(resp1)
  expect_equal(out, character())

  sync(resp1)
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
  wait_for_http_data(resp1)

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
    sync(resp1)
  }
  wait_for_complete(resp1)
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
  wait_for_http_data(resp2)
  expect_equal(resp_stream_lines(resp2, 3), c("a", "b", "c"))
  expect_equal(resp_stream_lines(resp2, 3), c("d", "e"))
  expect_equal(resp_stream_lines(resp2, 3), character())
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

test_that("stream_split_lines() splits on LF, CR, and CRLF", {
  split <- function(x, eat_lf = FALSE) {
    stream_split_lines(charToRaw(x), "UTF-8", eat_lf = eat_lf, max_size = Inf)
  }

  out <- split("a\nb\r\nc\rd\n")
  expect_equal(out$lines, c("a", "b", "c", "d"))
  expect_equal(out$remainder, raw())
  expect_false(out$eat_lf)

  # blank lines are preserved
  expect_equal(split("a\n\nb\n")$lines, c("a", "", "b"))

  # trailing bytes without an ending become the remainder
  out <- split("a\nbcd")
  expect_equal(out$lines, "a")
  expect_equal(out$remainder, charToRaw("bcd"))
})

test_that("stream_split_lines() handles a CRLF split across reads", {
  # A buffer ending in a bare CR emits the line but flags that a following LF
  # should be swallowed.
  out <- stream_split_lines(
    charToRaw("a\r"),
    "UTF-8",
    eat_lf = FALSE,
    max_size = Inf
  )
  expect_equal(out$lines, "a")
  expect_equal(out$remainder, raw())
  expect_true(out$eat_lf)

  # ... and on the next read that leading LF is dropped.
  out <- stream_split_lines(
    charToRaw("\nb\n"),
    "UTF-8",
    eat_lf = TRUE,
    max_size = Inf
  )
  expect_equal(out$lines, "b")
})

test_that("stream_split_lines() enforces max_size", {
  expect_snapshot(
    error = TRUE,
    stream_split_lines(
      charToRaw("aaaaa"),
      "UTF-8",
      eat_lf = FALSE,
      max_size = 3
    )
  )
})
