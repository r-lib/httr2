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
