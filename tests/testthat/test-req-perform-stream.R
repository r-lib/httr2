test_that("req_perform_stream() has been soft deprecated", {
  req <- request_test("/stream-bytes/1024")
  expect_snapshot(. <- req_perform_stream(req, \(x) NULL))
})

# req_perform_stream() --------------------------------------------------------

test_that("returns stream body; sets last request & response", {
  withr::local_options(lifecycle_verbosity = "quiet")

  req <- request_test("/stream-bytes/1024")
  resp <- req_perform_stream(req, function(x) NULL)
  expect_s3_class(resp, "httr2_response")
  expect_false(resp_has_body(resp))

  expect_equal(last_request(), req_policies(req, connection = TRUE))
  expect_equal(last_response(), resp)
})

test_that("HTTP errors become R errors", {
  withr::local_options(lifecycle_verbosity = "quiet")

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
  withr::local_options(lifecycle_verbosity = "quiet")

  req <- request_test("/base64/:value", value = "YWJj") |>
    req_error(is_error = function(resp) TRUE)

  expect_error(
    req |> req_perform_stream(function(x) NULL),
    class = "httr2_http_200"
  )

  resp <- last_response()
  expect_s3_class(resp, "httr2_response")
  # This also allows us to check that the body is set correctly
  # since that httpbin error responses have empty bodies
  expect_equal(resp_body_string(resp), "abc")
})

test_that("can buffer to lines", {
  withr::local_options(lifecycle_verbosity = "quiet")

  lines <- character()
  accumulate_lines <- function(x) {
    lines <<- c(lines, strsplit(rawToChar(x), "\n", fixed = TRUE)[[1]])
    TRUE
  }

  # Each line is 225 bytes, should should be split into ~2 pieces
  resp <- request_test("/stream/10") |>
    req_perform_stream(accumulate_lines, buffer_kb = 0.1, round = "line")
  expect_equal(length(lines), 10)

  valid_json <- map_lgl(lines, jsonlite::validate)
  expect_equal(valid_json, rep(TRUE, 10))
})

test_that("can supply custom rounding", {
  withr::local_options(lifecycle_verbosity = "quiet")

  out <- list()
  accumulate <- function(x) {
    out <<- c(out, list(x))
    TRUE
  }

  resp <- request_test("/stream-bytes/1024") |>
    req_perform_stream(
      accumulate,
      buffer_kb = 0.1,
      round = function(bytes) if (length(bytes) > 100) 100 else integer()
    )
  expect_equal(lengths(out), c(rep(100, 10), 24))
})

test_that("eventually terminates even if never rounded", {
  withr::local_options(lifecycle_verbosity = "quiet")

  out <- raw()
  accumulate <- function(x) {
    out <<- c(out, x)
    TRUE
  }

  resp <- request_test("/stream-bytes/1024") |>
    req_perform_stream(
      accumulate,
      buffer_kb = 0.1,
      round = function(bytes) integer()
    )
  expect_equal(length(out), 1024)
})


test_that("req_perform_stream checks its inputs", {
  withr::local_options(lifecycle_verbosity = "quiet")

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
