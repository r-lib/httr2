test_that("can extract request timing", {
  req <- request_test()
  resp <- req_perform(req)
  expect(is_bare_numeric(resp_timing(resp)), "timing vector is not numeric")
  expect_contains(names(resp_timing(resp)), "total")
})
