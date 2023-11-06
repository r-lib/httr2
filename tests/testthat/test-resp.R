test_that("response has basic print method", {

  file.create("path-empty")
  writeBin("sample content", "path-content")

  withr::defer(unlink(c("path-empty", "path-content")))

  expect_snapshot({
    response(200)
    response(200, headers = "Content-Type: text/html")
    response(200, body = charToRaw("abcdef"))
    response(200, body = new_path("path-empty"))
    response(200, body = new_path("path-content"))
  })
})

test_that("response checks its inputs", {
  expect_snapshot(error = TRUE, {
    response(status_code = "abc")
    response(url = 1)
    response(method = 1)
    response(headers = 1)
  })
})

test_that("response adds date if not provided by server", {
  resp <- response(headers = "Test: 1")
  expect_named(resp_headers(resp), c("Test", "Date"))
})

test_that("response adds default METHOD", {
  # for backward compatibility
  resp <- response(method = NULL)
  expect_equal(resp$method, "GET")
})

test_that("check_response produces helpful error", {
  expect_snapshot(check_response(1), error = TRUE)
})
