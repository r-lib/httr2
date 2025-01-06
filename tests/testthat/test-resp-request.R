test_that("can extract request", {
  req <- request_test()
  resp <- req_perform(req)
  expect_equal(resp_request(resp), req)
})
