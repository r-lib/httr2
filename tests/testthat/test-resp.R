test_that("respinse has basic print method", {
  expect_snapshot(req_fetch(req("https://httpbin.org/")))
})
