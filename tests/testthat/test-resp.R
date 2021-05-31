test_that("respinse has basic print method", {
  expect_snapshot(response(200, "https://httpbin.org/"))
})
