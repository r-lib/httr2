test_that("can determine if incomplete data is complete", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("data: 1\n\n")
    res$send_chunk("data: ")
  })

  con <- req |> req_perform_connection(blocking = TRUE)
  withr::defer(close(con))

  expect_equal(
    resp_stream_sse(con, 10),
    list(type = "message", data = "1", id = "")
  )
  expect_snapshot(expect_equal(resp_stream_sse(con), NULL))
  expect_true(resp_stream_is_complete(con))
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

test_that("max_size counts the buffered event bytes, delimiter included", {
  # The event with its "\r\n\r\n" delimiter is 11 bytes; max_size limits the
  # buffered bytes (delimiter included), approximately.
  data <- charToRaw("data: 1\r\n\r\n")
  resp1 <- local_streaming_response(data)

  expect_equal(
    resp_stream_sse(resp1, max_size = 10),
    list(type = "message", data = "1", id = "")
  )

  resp2 <- local_streaming_response(data)
  expect_error(
    resp_stream_sse(resp2, max_size = 9),
    class = "httr2_streaming_error"
  )
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

test_that("sse always interprets data as UTF-8", {
  req <- local_app_request(function(req, res) {
    res$send_chunk("data: \xE3\x81\x82\r\n\r\n")
  })

  # Data is decoded as UTF-8 regardless of the locale.
  withr::local_locale(LC_CTYPE = "C")
  resp <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp))

  out <- resp_stream_sse(resp)

  s <- "\xE3\x81\x82"
  Encoding(s) <- "UTF-8"
  expect_equal(out, list(type = "message", data = s, id = ""))
  expect_equal(Encoding(out$data), "UTF-8")
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

test_that("has a working find_event_boundaries", {
  # Splits the buffer at the first boundary into the matched event and the
  # remaining bytes.
  boundary_test <- function(x, matched, remaining) {
    buffer <- charToRaw(x)
    splits <- find_event_boundaries(buffer)
    result <- if (length(splits) == 0) {
      NULL
    } else {
      split_at <- splits[[1]]
      list(
        matched = slice(buffer, end = split_at),
        remaining = slice(buffer, start = split_at)
      )
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

  # Finds every boundary in the buffer
  expect_equal(find_event_boundaries(charToRaw("a\n\nb\n\n")), c(4L, 7L))
  expect_equal(
    find_event_boundaries(charToRaw("a\r\n\r\nb\r\n\r\n")),
    c(6L, 11L)
  )

  # Non-matches
  expect_length(find_event_boundaries(charToRaw("\n\r\n\r")), 0)
  expect_length(find_event_boundaries(charToRaw("hello\ngoodbye\n")), 0)
  expect_length(find_event_boundaries(charToRaw("")), 0)
  expect_length(find_event_boundaries(charToRaw("1")), 0)
  expect_length(find_event_boundaries(charToRaw("12")), 0)
  expect_length(find_event_boundaries(charToRaw("\r\n\r")), 0)
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

test_that("event and id fields are parsed", {
  event <- parse_event("event: ping\ndata: x\nid: 42")
  expect_equal(event$type, "ping")
  expect_equal(event$data, "x")
  expect_equal(event$id, "42")
})
