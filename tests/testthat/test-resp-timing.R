test_that("can extract request timing", {
  req <- response(timing = c(total = 1))
  expect_equal(resp_timing(req), c(total = 1))
})
