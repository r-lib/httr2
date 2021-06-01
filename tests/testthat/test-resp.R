test_that("respinse has basic print method", {
  expect_snapshot({
    response(200, "https://example.com/")
    response(200, "https://example.com/", headers = "Content-Type: text/html")
    response(200, "https://example.com/", body = charToRaw("abcdef"))
    response(200, "https://example.com/", body = new_path("/test"))
  })
})

test_that("check_response produces helpful error", {
  expect_snapshot(check_response(1), error = TRUE)
})
