test_that("respinse has basic print method", {
  expect_snapshot({
    response(200)
    response(200, headers = "Content-Type: text/html")
    response(200, body = charToRaw("abcdef"))
    response(200, body = new_path("/test"))
  })
})

test_that("response adds date if not provided by server", {
  resp <- response(headers = "Test: 1")
  expect_named(resp_headers(resp), c("Test", "Date"))
})

test_that("check_response produces helpful error", {
  expect_snapshot(check_response(1), error = TRUE)
})
