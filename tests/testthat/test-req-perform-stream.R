test_that("req_stream() is deprecated", {
  req <- request(example_url()) %>% req_url_path("/stream-bytes/100")
  expect_snapshot(
    resp <- req_stream(req, identity, buffer_kb = 32)
  )
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

test_that("as_round_function checks its inputs", {
  expect_snapshot(error = TRUE, {
    as_round_function(1)
    as_round_function("bytes")
    as_round_function(function(x) 1)
  })
})
