test_that("req has basic print method", {
  expect_snapshot({
    req <- request("https://example.com")
    req
    req |> req_body_raw("Test")
    req |> req_body_multipart("Test" = 1)
  })
})

test_that("printing headers works with {}", {
  expect_snapshot(req_headers(request("http://test"), x = "{z}", `{z}` = "x"))
})

test_that("individually prints repeated headers", {
  expect_snapshot(request("https://example.com") |> req_headers(A = 1:3))
})

test_that("print method obfuscates Authorization header unless requested", {
  req <- request("https://example.com") |>
    req_auth_basic("user", "SECRET")
  output <- testthat::capture_messages(print(req))
  expect_false(any(grepl("SECRET", output, fixed = TRUE)))

  output <- capture.output(print(req, redact_headers = FALSE))
  expect_true(any(grepl("Authorization: \"Basic", output, fixed = TRUE)))
  expect_false(any(grepl("REDACTED", output, fixed = TRUE)))
})

test_that("check_request() gives useful error", {
  expect_snapshot(check_request(1), error = TRUE)
})
