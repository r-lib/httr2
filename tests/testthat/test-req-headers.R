test_that("can add and remove headers", {
  req <- req("http://example.com")
  req <- req %>% req_headers(x = 1)
  expect_equal(req$headers, list(x = 1))
  req <- req %>% req_headers(x = NULL)
  expect_equal(req$headers, list())
})

test_that("can add header called req", {
  req <- req("http://example.com")
  req <- req %>% req_headers(req = 1)
  expect_equal(req$headers, list(req = 1))
})
