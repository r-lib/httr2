test_that("req has basic print method", {
  expect_snapshot(req("https://r-project.org"))
})
