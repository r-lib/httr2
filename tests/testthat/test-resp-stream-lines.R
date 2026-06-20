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
  # Buffered bytes mean the stream isn't complete, even between lines.
  expect_false(resp_stream_is_complete(resp1))

  out <- resp_stream_lines(resp1)
  expect_equal(out, character())

  sync(resp1)
  out <- resp_stream_lines(resp1)
  expect_equal(out, "This is a complete sentence.")
})

test_that("handles LF and CRLF line endings, including CRLF split across reads", {
  sync <- sync_req("endings")
  req <- local_app_request(function(req, res) {
    sync <- req$app$locals$sync_rep("endings")

    res$set_header("Content-Type", "text/plain; charset=Shift_JIS")
    res$send_chunk(as.raw(c(0x82, 0xA0, 0x0A)))
    sync(res$send_chunk("crlf\r\n"))
    sync(res$send_chunk("lf\n"))
    sync(res$send_chunk("half line/"))
    sync(res$send_chunk("other half\n"))
    sync(res$send_chunk("split crlf\r"))
    sync(res$send_chunk("\nanother line\n"))
    sync(res$send_chunk("eof without line ending"))
  })

  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))
  wait_for_http_data(resp1)

  # A chunk ending mid-line (a partial line, or the CR half of a CRLF) yields
  # nothing until the next read completes it.
  expected_values <- list(
    "\u3042",
    "crlf",
    "lf",
    character(0),
    "half line/other half",
    character(0),
    "split crlf"
  )

  for (expected in expected_values) {
    rlang::inject(expect_equal(resp_stream_lines(resp1), !!expected))
    sync(resp1)
  }
  # "split crlf" and "another line" were split from one buffer, so the second
  # is served from the queue without a further read.
  expect_equal(resp_stream_lines(resp1), "another line")

  wait_for_complete(resp1)
  # A final line without a terminator is returned (silently).
  expect_equal(resp_stream_lines(resp1), "eof without line ending")
  expect_equal(resp_stream_lines(resp1), character(0))

  # Same test, but now, blocking (and without sync)
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
  resp2 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp2))

  expected_values <- c(
    "\u3042",
    "crlf",
    "lf",
    "half line/other half",
    "split crlf",
    "another line"
  )

  for (expected in expected_values) {
    rlang::inject(expect_equal(resp_stream_lines(resp2), !!expected))
  }
  expect_equal(resp_stream_lines(resp2), "eof without line ending")
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
  split <- function(x) {
    stream_split_lines(charToRaw(x), "UTF-8", max_size = Inf)
  }

  out <- split("a\nb\r\nc\n")
  expect_equal(out$blocks, list("a", "b", "c"))
  expect_equal(out$remainder, raw())

  # blank lines are preserved
  expect_equal(split("a\n\nb\n")$blocks, list("a", "", "b"))

  # trailing bytes without an ending become the remainder
  out <- split("a\nbcd")
  expect_equal(out$blocks, list("a"))
  expect_equal(out$remainder, charToRaw("bcd"))
})

test_that("stream_split_lines() treats a bare CR as an ordinary character", {
  split <- function(x) {
    stream_split_lines(charToRaw(x), "UTF-8", max_size = Inf)
  }

  # A CR not followed by LF is kept in the line, not used as a separator.
  out <- split("a\rb\n")
  expect_equal(out$blocks, list("a\rb"))
  expect_equal(out$remainder, raw())

  # A CRLF split across reads needs no special handling: the trailing CR is
  # just unfinished content in the remainder until the next read supplies the
  # LF.
  out <- split("a\r")
  expect_equal(out$blocks, list())
  expect_equal(out$remainder, charToRaw("a\r"))

  out <- split("a\r\nb\n")
  expect_equal(out$blocks, list("a", "b"))
  expect_equal(out$remainder, raw())
})

test_that("stream_split_lines() enforces max_size", {
  # Buffer with no line ending yet.
  expect_snapshot(
    error = TRUE,
    stream_split_lines(charToRaw("aaaaa"), "UTF-8", max_size = 3)
  )

  # A complete line that is itself too long.
  expect_snapshot(
    error = TRUE,
    stream_split_lines(charToRaw("aaaaa\n"), "UTF-8", max_size = 3)
  )
})
