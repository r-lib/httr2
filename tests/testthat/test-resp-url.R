test_that("can extract url components from a response", {
  resp <- req_perform(request_test("/get?a=1&b=2"))

  expect_equal(resp_url(resp), paste0(example_url(), "get?a=1&b=2"))
  expect_equal(resp_url_path(resp), "/get")
  expect_equal(resp_url_queries(resp), list(a = "1", b = "2"))

  expect_equal(resp_url_query(resp, "a"), "1")
  expect_equal(resp_url_query(resp, "c"), NULL)
  expect_equal(resp_url_query(resp, "c", "x"), "x")
})
