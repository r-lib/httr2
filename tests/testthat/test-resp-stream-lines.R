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

test_that("max_size is approximate, counting the buffered delimiter bytes", {
  # A line whose content is exactly max_size is returned: we read one byte past
  # max_size, enough to capture a single LF terminator.
  resp <- local_streaming_response(c(rep(as.raw(0x61), 10), as.raw(0x0A)))
  expect_equal(resp_stream_lines(resp, max_size = 10), strrep("a", 10))

  # A two-byte CRLF tips the buffer one byte over, so the same line needs a
  # slightly larger max_size.
  crlf <- c(rep(as.raw(0x61), 10), as.raw(c(0x0D, 0x0A)))
  resp <- local_streaming_response(crlf)
  expect_error(
    resp_stream_lines(resp, max_size = 10),
    class = "httr2_streaming_error"
  )
  expect_equal(resp_stream_lines(resp, max_size = 11), strrep("a", 10))
})

test_that("max_size counts an incomplete delimiter at EOF as content", {
  resp <- local_streaming_response(c(rep(as.raw(0x61), 10), as.raw(0x0D)))

  expect_error(
    resp_stream_lines(resp, max_size = 10),
    class = "httr2_streaming_error"
  )
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

test_that("LineSplitter flushes a trailing line as a raw block", {
  s <- LineSplitter$new()
  # Nothing buffered: nothing to flush.
  expect_equal(s$finish(raw()), list())
  # Trailing bytes are emitted as a final block.
  expect_equal(s$finish(charToRaw("tail")), list(charToRaw("tail")))
  # A bare CR is ordinary content, even at end-of-stream.
  expect_equal(s$finish(charToRaw("tail\r")), list(charToRaw("tail\r")))
})

test_that("LineSplitter splits on LF and CRLF, keeping the terminator", {
  s <- LineSplitter$new()

  out <- s$split(charToRaw("a\nb\r\nc\n"))
  expect_equal(
    out$blocks,
    list(charToRaw("a\n"), charToRaw("b\r\n"), charToRaw("c\n"))
  )
  expect_equal(out$remainder, raw())

  # blank lines are preserved
  expect_equal(
    s$split(charToRaw("a\n\nb\n"))$blocks,
    list(charToRaw("a\n"), charToRaw("\n"), charToRaw("b\n"))
  )

  # trailing bytes without an ending become the remainder
  out <- s$split(charToRaw("a\nbcd"))
  expect_equal(out$blocks, list(charToRaw("a\n")))
  expect_equal(out$remainder, charToRaw("bcd"))

  # A bare CR is not a terminator; a CRLF split across reads needs no special
  # handling (the trailing CR stays in the remainder until its LF arrives).
  out <- s$split(charToRaw("a\rb\n"))
  expect_equal(out$blocks, list(charToRaw("a\rb\n")))
  out <- s$split(charToRaw("a\r"))
  expect_equal(out$blocks, list())
  expect_equal(out$remainder, charToRaw("a\r"))
})

test_that("stream_parse_lines() decodes blocks and strips LF/CRLF terminators", {
  blocks <- list(
    charToRaw("a\n"),
    charToRaw("b\r\n"),
    charToRaw("\n"),
    charToRaw("tail")
  )
  expect_equal(stream_parse_lines(blocks, "UTF-8"), c("a", "b", "", "tail"))

  # honors the encoding, and a bare CR stays as content
  expect_equal(
    stream_parse_lines(list(as.raw(c(0x82, 0xA0, 0x0A))), "Shift_JIS"),
    "あ"
  )
  expect_equal(stream_parse_lines(list(charToRaw("a\rb\n")), "UTF-8"), "a\rb")

  # no blocks gives an empty vector
  expect_equal(stream_parse_lines(list(), "UTF-8"), character())
})
