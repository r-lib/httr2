test_that("req_stream() is deprecated", {
  req <- request(example_url()) %>% req_url_path("/stream-bytes/100")
  expect_snapshot(
    resp <- req_stream(req, identity, buffer_kb = 32)
  )
})

# req_perform_connection() ----------------------------------------------------

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

test_that("can read all data from a connection", {
  resp <- request_test("/stream-bytes/2048") %>% req_perform_connection()
  withr::defer(close(resp))

  out <- resp_body_raw(resp)
  expect_length(out, 2048)
  expect_false(resp_has_body(resp))
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
  skip_on_covr()
  app <- webfakes::new_app()

  app$get("/events", function(req, res) {
    res$send_chunk("This is a ")
    Sys.sleep(0.2)
    res$send_chunk("complete sentence.\n")
  })
  server <- webfakes::local_app_process(app)
  req <- request(server$url("/events"))

  # Non-blocking returns NULL until data is ready
  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))

  out <- resp_stream_lines(resp1)
  expect_equal(out, character())
  expect_equal(resp1$cache$push_back, charToRaw("This is a "))

  while(length(out) == 0) {
    Sys.sleep(0.1)
    out <- resp_stream_lines(resp1)    
  }
  expect_equal(out, "This is a complete sentence.")
})

test_that("handles line endings of multiple kinds", {
  skip_on_covr()
  app <- webfakes::new_app()

  app$get("/events", function(req, res) {
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

  server <- webfakes::local_app_process(app)
  req <- request(server$url("/events"))

  resp1 <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp1))

  for (expected in c("crlf", "lf", "cr", "half line/other half", "broken crlf", "another line")) {
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

  for (expected in c("crlf", "lf", "cr", "half line/other half", "broken crlf", "another line")) {
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
  skip_on_covr()
  app <- webfakes::new_app()

  app$get("/events", function(req, res) {
    res$send_chunk(paste(letters[1:5], collapse = "\n"))
  })

  server <- webfakes::local_app_process(app)
  req <- request(server$url("/events"))

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
})

test_that("can feed sse events one at a time", {
  skip_on_covr()
  app <- webfakes::new_app()

  app$get("/events", function(req, res) {
    for(i in 1:3) {
      res$send_chunk(sprintf("data: %s\n\n", i))
    }
  })

  server <- webfakes::local_app_process(app)
  req <- request(server$url("/events"))
  resp <- req_perform_connection(req)
  withr::defer(close(resp))

  expect_equal(
    resp_stream_sse(resp),
    list(type = "message", data = "1", id = character())
  )
  expect_equal(
    resp_stream_sse(resp),
    list(type = "message", data = "2", id = character())
  )
  resp_stream_sse(resp)

  expect_equal(resp_stream_sse(resp), NULL)
})

test_that("can join sse events across multiple reads", {
  skip_on_covr()
  app <- webfakes::new_app()

  app$get("/events", function(req, res) {
    res$send_chunk("data: 1\n")
    Sys.sleep(0.2)
    res$send_chunk("data")
    Sys.sleep(0.2)
    res$send_chunk(": 2\n")
    res$send_chunk("\ndata: 3\n\n")
  })
  server <- webfakes::local_app_process(app)
  req <- request(server$url("/events"))

  # Non-blocking returns NULL until data is ready
  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))

  out <- resp_stream_sse(resp1)
  expect_equal(out, NULL)
  expect_equal(resp1$cache$push_back, charToRaw("data: 1\n"))

  while(is.null(out)) {
    Sys.sleep(0.1)
    out <- resp_stream_sse(resp1)
  }
  expect_equal(out, list(type = "message", data = c("1", "2"), id = character()))
  expect_equal(resp1$cache$push_back, charToRaw("data: 3\n\n"))
  out <- resp_stream_sse(resp1)
  expect_equal(out, list(type = "message", data = "3", id = character()))
  
  # Blocking waits for a complete event
  resp2 <- req_perform_connection(req)
  withr::defer(close(resp2))

  out <- resp_stream_sse(resp2)
  expect_equal(out, list(type = "message", data = c("1", "2"), id = character()))
})

test_that("sse always interprets data as UTF-8", {
  skip_on_covr()
  app <- webfakes::new_app()

  app$get("/events", function(req, res) {
    res$send_chunk("data: \xE3\x81\x82\r\n\r\n")
  })
  server <- webfakes::local_app_process(app)
  req <- request(server$url("/events"))

  withr::with_locale(c(LC_CTYPE = "C"), {
    # Non-blocking returns NULL until data is ready
    resp1 <- req_perform_connection(req, blocking = FALSE)
    withr::defer(close(resp1))

    out <- NULL
    while(is.null(out)) {
      Sys.sleep(0.1)
      out <- resp_stream_sse(resp1)
    }

    s <- "\xE3\x81\x82"
    Encoding(s) <- "UTF-8"
    expect_equal(out, list(type = "message", data = s, id = character()))
    expect_equal(Encoding(out$data), "UTF-8")
    expect_equal(resp1$cache$push_back, raw())
  })
})

test_that("streaming size limits enforced", {
  skip_on_covr()
  app <- webfakes::new_app()

  app$get("/events", function(req, res) {
    data_size <- 1000
    data <- paste(rep_len("0", data_size), collapse = "")
    res$send_chunk(data)
  })
  server <- webfakes::local_app_process(app)
  req <- request(server$url("/events"))

  resp1 <- req_perform_connection(req, blocking = FALSE)
  withr::defer(close(resp1))
  expect_error(
    while(is.null(out)) {
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
      list(matched=charToRaw(matched), remaining = charToRaw(remaining))
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

test_that("has a working slice", {
  x <- letters[1:5]
  expect_identical(slice(x), x)
  expect_identical(slice(x, 1, length(x) + 1), x)
  
  # start is inclusive, end is exclusive
  expect_identical(slice(x, 1, length(x)), head(x, -1))
  # zero-length slices are fine
  expect_identical(slice(x, 1, 1), character())
  # starting off the end is fine
  expect_identical(slice(x, length(x) + 1), character())
  expect_identical(slice(x, length(x) + 1, length(x) + 1), character())
  # slicing zero-length is fine
  expect_identical(slice(character()), character())

  # out of bounds
  expect_error(slice(x, 0, 1))
  expect_error(slice(x, length(x) + 2))
  expect_error(slice(x, end = length(x) + 2))
  # end too small relative to start
  expect_error(slice(x, 2, 1))
})

# req_perform_stream() --------------------------------------------------------

test_that("returns stream body; sets last request & response", {
  req <- request_test("/stream-bytes/1024")
  resp <- req_perform_stream(req, function(x) NULL)
  expect_s3_class(resp, "httr2_response")
  expect_false(resp_has_body(resp))

  expect_equal(last_request(), req)
  expect_equal(last_response(), resp)
})

test_that("HTTP errors become R errors", {
  req <- request_test("/status/404")
  expect_error(
    req_perform_stream(req, function(x) TRUE),
    class = "httr2_http_404"
  )

  resp <- last_response()
  expect_s3_class(resp, "httr2_response")
  expect_equal(resp$status_code, 404)
})

test_that("can override error handling", {
  req <- request_test("/base64/:value", value = "YWJj") %>%
    req_error(is_error = function(resp) TRUE)

  expect_error(
    req %>% req_perform_stream(function(x) NULL),
    class = "httr2_http_200"
  )

  resp <- last_response()
  expect_s3_class(resp, "httr2_response")
  # This also allows us to check that the body is set correctly
  # since that httpbin error responses have empty bodies
  expect_equal(resp_body_string(resp), "abc")
})

test_that("can buffer to lines", {
  lines <- character()
  accumulate_lines <- function(x) {
    lines <<- c(lines, strsplit(rawToChar(x), "\n")[[1]])
    TRUE
  }

  # Each line is 225 bytes, should should be split into ~2 pieces
  resp <- request_test("/stream/10") %>%
    req_perform_stream(accumulate_lines, buffer_kb = 0.1, round = "line")
  expect_equal(length(lines), 10)

  valid_json <- map_lgl(lines, jsonlite::validate)
  expect_equal(valid_json, rep(TRUE, 10))
})

test_that("can supply custom rounding", {
  out <- list()
  accumulate <- function(x) {
    out <<- c(out, list(x))
    TRUE
  }

  resp <- request_test("/stream-bytes/1024") %>%
    req_perform_stream(
      accumulate,
      buffer_kb = 0.1,
      round = function(bytes) if (length(bytes) > 100) 100 else integer()
    )
  expect_equal(lengths(out), c(rep(100, 10), 24))
})

test_that("eventually terminates even if never rounded", {
  out <- raw()
  accumulate <- function(x) {
    out <<- c(out, x)
    TRUE
  }

  resp <- request_test("/stream-bytes/1024") %>%
    req_perform_stream(
      accumulate,
      buffer_kb = 0.1,
      round = function(bytes) integer()
    )
  expect_equal(length(out), 1024)
})

test_that("req_perform_stream checks its inputs", {
  req <- request_test("/stream-bytes/1024")
  callback <- function(x) NULL

  expect_snapshot(error = TRUE, {
    req_perform_stream(1)
    req_perform_stream(req, 1)
    req_perform_stream(req, callback, timeout_sec = -1)
    req_perform_stream(req, callback, buffer_kb = "x")
  })
})

test_that("as_round_function checks its inputs", {
  expect_snapshot(error = TRUE, {
    as_round_function(1)
    as_round_function("bytes")
    as_round_function(function(x) 1)
  })
})
