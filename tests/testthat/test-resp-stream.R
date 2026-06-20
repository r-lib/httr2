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

test_that("resp_stream_raw() validates kb", {
  resp <- local_streaming_response(charToRaw("abc"))

  expect_length(resp_stream_raw(resp, kb = 1 / 1024), 1)
  expect_snapshot(resp_stream_raw(resp, kb = -1), error = TRUE)
  expect_snapshot(resp_stream_raw(resp, kb = Inf), error = TRUE)
})

test_that("resp_stream_is_complete() requires an open streaming response", {
  expect_snapshot(resp_stream_is_complete(response()), error = TRUE)

  resp <- local_streaming_response(charToRaw("abc"))
  close(resp)
  expect_snapshot(resp_stream_is_complete(resp), error = TRUE)
})

test_that("streaming responses use only one reader", {
  resp <- local_streaming_response(charToRaw("a\n"))

  expect_equal(resp_stream_lines(resp), "a")
  expect_snapshot(resp_stream_raw(resp), error = TRUE)
})

test_that("BoundarySplitter splits, caps reads, and discards trailers", {
  s <- BoundarySplitter$new(find_event_boundaries)

  out <- s$split(charToRaw("a\n\nb"))
  expect_equal(out$blocks, list(charToRaw("a\n\n")))
  expect_equal(out$remainder, charToRaw("b"))

  # A buffer ending exactly on a boundary leaves an empty remainder.
  out <- s$split(charToRaw("a\n\n"))
  expect_equal(out$blocks, list(charToRaw("a\n\n")))
  expect_equal(out$remainder, raw())

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
  expect_equal(s$read_cap(raw(), 10), 11)
  expect_equal(s$read_cap(raw(4), 10), 7)
  expect_equal(s$read_cap(raw(), Inf), stream_chunk_bytes)
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

test_that("stream_pull() keeps size errors reproducible on retry", {
  resp <- local_streaming_response(c(rep(as.raw(0x61), 11), as.raw(0x0A)))

  expect_error(
    resp_stream_lines(resp, max_size = 10),
    class = "httr2_streaming_error"
  )
  expect_error(
    resp_stream_lines(resp, max_size = 10),
    class = "httr2_streaming_error"
  )
})

test_that("stream_pull() preserves state when splitting fails", {
  FlakySplitter <- R6::R6Class(
    "FlakySplitter",
    inherit = StreamSplitter,
    public = list(
      failed = FALSE,
      split = function(buffer) {
        if (!self$failed) {
          self$failed <- TRUE
          cli::cli_abort("Failed to split.")
        }
        list(
          blocks = list(buffer),
          remainder = raw(),
          sizes = length(buffer)
        )
      }
    )
  )

  resp <- local_streaming_response(charToRaw("abc"))
  splitter <- FlakySplitter$new()

  expect_snapshot(stream_pull(resp, 1, splitter, Inf), error = TRUE)
  expect_equal(resp$cache$push_back, charToRaw("abc"))
  expect_equal(stream_pull(resp, 1, splitter, Inf), list(charToRaw("abc")))
})

test_that("stream_pull() preserves queued blocks when a later split fails", {
  ByteBody <- R6::R6Class(
    "ByteBody",
    inherit = StreamingBody,
    public = list(
      initialize = function(bytes) {
        private$bytes <- bytes
      },
      read = function(n) {
        if (length(private$bytes) == 0L) {
          return(raw())
        }
        out <- private$bytes[[1L]]
        private$bytes <- private$bytes[-1L]
        out
      },
      is_open = function() TRUE,
      is_complete = function() length(private$bytes) == 0L,
      close = function() invisible()
    ),
    private = list(
      bytes = NULL
    )
  )
  FlakySplitter <- R6::R6Class(
    "FlakyQueuedSplitter",
    inherit = StreamSplitter,
    public = list(
      failed = FALSE,
      split = function(buffer) {
        if (identical(buffer, charToRaw("b")) && !self$failed) {
          self$failed <- TRUE
          cli::cli_abort("Failed to split.")
        }
        list(
          blocks = list(buffer),
          remainder = raw(),
          sizes = length(buffer)
        )
      }
    )
  )

  resp <- response(body = ByteBody$new(charToRaw("ab")))
  splitter <- FlakySplitter$new()

  expect_snapshot(stream_pull(resp, Inf, splitter, Inf), error = TRUE)
  expect_equal(
    stream_pull(resp, Inf, splitter, Inf),
    list(charToRaw("a"), charToRaw("b"))
  )
})

test_that("stream_pull() flushes a trailing block at end of stream", {
  req <- local_app_request(function(req, res) {
    # "b" has no trailing line ending, so it can't be served until EOF.
    res$send_chunk("a\nb")
  })
  resp <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp))

  expect_equal(resp_stream_lines(resp, 1), "a")
  # At end of stream the splitter flushes its buffered remainder as a block.
  expect_equal(resp_stream_lines(resp, 1), "b")
  expect_equal(resp_stream_lines(resp, 1), character())
})

test_that("verbosity = 3 logs the buffered chunk", {
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
