test_that("response has basic print method", {
  file.create("path-empty")
  writeBin("sample content", "path-content")

  withr::defer(unlink(c("path-empty", "path-content")))
  con <- file()
  withr::defer(close(con))

  expect_snapshot({
    response(200)
    response(200, headers = "Content-Type: text/html")
    response(200, body = charToRaw("abcdef"))
    response(200, body = new_path("path-empty"))
    response(200, body = new_path("path-content"))
    response(200, body = con)
  })
})

test_that("response adds date if not provided by server", {
  resp <- response(headers = "Test: 1")
  expect_named(resp_headers(resp), c("Test", "Date"))
})

test_that("check_response produces helpful error", {
  expect_snapshot(check_response(1), error = TRUE)
})

test_that("new_response() checks its inputs", {
  expect_snapshot(error = TRUE, {
    new_response(1)
    new_response("GET", 1)
    new_response("GET", "http://x.com", "x")
    new_response("GET", "http://x.com", 200, 1)
    new_response("GET", "http://x.com", 200, list(), 1)
    new_response("GET", "http://x.com", 200, list(), raw(), "x")
    new_response("GET", "http://x.com", 200, list(), raw(), c(x = 1), 1)
  })
})
