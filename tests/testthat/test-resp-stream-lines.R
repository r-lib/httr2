test_that("decodes the response encoding and joins LF and CRLF lines", {
  # Lines are decoded with the response encoding (here Shift_JIS) and split on
  # both LF and CRLF, including a CRLF straddling two reads ("split crlf\r" then
  # "\n"); a final line without a terminator is returned at EOF.
  req <- local_app_request(function(req, res) {
    res$set_header("Content-Type", "text/plain; charset=Shift_JIS")
    res$send_chunk(as.raw(c(0x82, 0xA0, 0x0A)))
    res$send_chunk("crlf\r\n")
    res$send_chunk("lf\n")
    res$send_chunk("half line/")
    res$send_chunk("other half\n")
    res$send_chunk("split crlf\r")
    res$send_chunk("\nanother line\n")
    res$send_chunk("eof without line ending")
  })
  resp <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp))

  expected_values <- c(
    "\u3042",
    "crlf",
    "lf",
    "half line/other half",
    "split crlf",
    "another line"
  )

  for (expected in expected_values) {
    rlang::inject(expect_equal(resp_stream_lines(resp), !!expected))
  }
  expect_equal(resp_stream_lines(resp), "eof without line ending")
})

test_that("requesting zero lines returns an empty vector", {
  req <- local_app_request(function(req, res) res$send_chunk("a\n"))
  resp <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp))
  expect_equal(resp_stream_lines(resp, 0), character())
})

test_that("resp_stream_lines(warn) is deprecated unless FALSE", {
  req <- local_app_request(function(req, res) res$send_chunk("a\n"))
  resp <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp))

  # warn = FALSE already requested silence, so it's accepted quietly.
  expect_no_warning(. <- resp_stream_lines(resp, warn = FALSE))
  # Any other value is deprecated.
  expect_snapshot(. <- resp_stream_lines(resp, warn = TRUE))
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

test_that("LineSplitter flushes a trailing line", {
  s <- LineSplitter$new("UTF-8")
  # Nothing buffered: nothing to flush.
  expect_equal(s$finish(raw()), list())
  # Trailing bytes are emitted as a final line.
  expect_equal(s$finish(charToRaw("tail")), list("tail"))
  # A bare CR is ordinary content, even at end-of-stream.
  expect_equal(s$finish(charToRaw("tail\r")), list("tail\r"))
})

test_that("stream_split_lines() splits on LF and CRLF", {
  out <- stream_split_lines(charToRaw("a\nb\r\nc\n"))
  expect_equal(out$blocks, list("a", "b", "c"))
  expect_equal(out$remainder, raw())

  # blank lines are preserved
  expect_equal(
    stream_split_lines(charToRaw("a\n\nb\n"))$blocks,
    list("a", "", "b")
  )

  # trailing bytes without an ending become the remainder
  out <- stream_split_lines(charToRaw("a\nbcd"))
  expect_equal(out$blocks, list("a"))
  expect_equal(out$remainder, charToRaw("bcd"))
})

test_that("stream_split_lines() treats a bare CR as an ordinary character", {
  # A CR not followed by LF is kept in the line, not used as a separator.
  out <- stream_split_lines(charToRaw("a\rb\n"))
  expect_equal(out$blocks, list("a\rb"))
  expect_equal(out$remainder, raw())

  # A CRLF split across reads needs no special handling: the trailing CR is
  # just unfinished content in the remainder until the next read supplies the
  # LF.
  out <- stream_split_lines(charToRaw("a\r"))
  expect_equal(out$blocks, list())
  expect_equal(out$remainder, charToRaw("a\r"))

  out <- stream_split_lines(charToRaw("a\r\nb\n"))
  expect_equal(out$blocks, list("a", "b"))
  expect_equal(out$remainder, raw())
})
