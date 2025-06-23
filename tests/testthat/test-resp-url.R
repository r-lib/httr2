test_that("can extract url components from a response", {
  req <- request_test("/get") %>% req_url_query(a = "1", b = "2")
  resp <- req_perform(req)

  expect_equal(resp_url(resp), example_url("/get?a=1&b=2"))
  expect_equal(resp_url_path(resp), "/get")
  expect_equal(resp_url_queries(resp), list(a = "1", b = "2"))

  expect_equal(resp_url_query(resp, "a"), "1")
  expect_equal(resp_url_query(resp, "c"), NULL)
  expect_equal(resp_url_query(resp, "c", "x"), "x")
})
