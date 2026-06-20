test_that("can stream bytes from a connection", {
  resp <- request_test("/stream-bytes/2048") |> req_perform_connection()
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
  resp <- request_test("/stream-bytes/2048") |> req_perform_connection()
  withr::defer(close(resp))

  expect_false(resp_stream_is_complete(resp))
  expect_length(resp_stream_raw(resp, kb = 2), 2048)
  expect_length(resp_stream_raw(resp, kb = 1), 0)
  expect_true(resp_stream_is_complete(resp))
})

test_that("can determine if a stream is complete (non-blocking)", {
  resp <- request_test("/stream-bytes/2048") |>
    req_perform_connection(blocking = FALSE)
  withr::defer(close(resp))

  expect_false(resp_stream_is_complete(resp))
  expect_length(resp_stream_raw(resp, kb = 2), 2048)
  expect_length(resp_stream_raw(resp, kb = 1), 0)
  expect_true(resp_stream_is_complete(resp))
})

test_that("can't read from a closed connection", {
  resp <- request_test("/stream-bytes/1024") |> req_perform_connection()
  close(resp)

  expect_false(resp_has_body(resp))
  expect_snapshot(resp_stream_raw(resp, 1), error = TRUE)

  # and no error if we try to close it again
  expect_no_error(close(resp))
})

test_that("streaming functions require a streaming response", {
  expect_snapshot(resp_stream_raw(response()), error = TRUE)
})

test_that("BoundarySplitter splits, caps reads, and discards trailers", {
  s <- BoundarySplitter$new(find_event_boundaries)

  out <- s$split(charToRaw("a\n\nb"))
  expect_equal(out$blocks, list(charToRaw("a\n\n")))
  expect_equal(out$remainder, charToRaw("b"))

  # No boundary: the whole buffer is the remainder (size limits are enforced by
  # stream_pull(), not split()).
  out <- s$split(charToRaw("abcdef"))
  expect_equal(out$blocks, list())
  expect_equal(out$remainder, charToRaw("abcdef"))

  # finish() drops nothing for an empty remainder but warns about a trailer.
  expect_equal(s$finish(raw()), list())
  expect_snapshot(out <- s$finish(charToRaw("b")))
  expect_equal(out, list())

  # read_cap() never reads more than one byte past the size limit.
  expect_equal(s$read_cap(0L, 10), 11)
  expect_equal(s$read_cap(4L, 10), 7)
  expect_equal(s$read_cap(0L, Inf), stream_chunk_bytes)
})

# stream_pull() drives every format (lines, sse, aws); these tests exercise its
# format-independent behavior through resp_stream_lines() as a convenient
# vehicle. Format-specific splitting and parsing are tested in the per-format
# files.

test_that("stream_pull() buffers incomplete blocks across reads (non-blocking)", {
  sync <- sync_req("pull")
  req <- local_app_request(function(req, res) {
    sync <- req$app$locals$sync_rep("pull")

    res$send_chunk("This is a ")
    sync(res$send_chunk("complete sentence.\n"))
  })

  resp <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp))
  wait_for_http_data(resp)

  # An incomplete block is held in push_back and nothing is served yet.
  expect_equal(resp_stream_lines(resp), character())
  expect_equal(resp$cache$push_back, charToRaw("This is a "))
  # Buffered bytes mean the stream isn't complete, even between blocks.
  expect_false(resp_stream_is_complete(resp))

  expect_equal(resp_stream_lines(resp), character())

  sync(resp)
  expect_equal(resp_stream_lines(resp), "This is a complete sentence.")
})

test_that("stream_pull() serves queued blocks from a single read", {
  req <- local_app_request(function(req, res) {
    res$send_chunk(paste0(letters[1:5], "\n", collapse = ""))
  })

  resp <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp))

  # All five blocks are split from one read; `n` limits how many are served and
  # the rest stay queued, so is_complete() is FALSE while the queue is non-empty.
  expect_equal(resp_stream_lines(resp, 3), c("a", "b", "c"))
  expect_false(resp_stream_is_complete(resp))
  expect_equal(resp_stream_lines(resp, 3), c("d", "e"))
  expect_equal(resp_stream_lines(resp, 3), character())
  expect_true(resp_stream_is_complete(resp))
})

test_that("stream_pull() enforces max_size (blocking and non-blocking)", {
  req <- local_app_request(function(req, res) {
    res$send_chunk(paste(rep_len("0", 1000), collapse = ""))
  })

  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))
  wait_for_http_data(resp1)
  expect_error(
    resp_stream_lines(resp1, max_size = 999),
    class = "httr2_streaming_error"
  )

  resp2 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp2))
  expect_error(
    resp_stream_lines(resp2, max_size = 999),
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
