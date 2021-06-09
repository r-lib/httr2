test_that("can modify url in various ways", {
  req <- request("http://example.com")

  expect_equal(req_url(req, "http://foo.com:10")$url, "http://foo.com:10")

  expect_equal(req_url_path(req, "index.html")$url, "http://example.com/index.html")
  req2 <- req %>%
    req_url_path_append("a") %>%
    req_url_path_append("index.html")
  expect_equal(req2$url, "http://example.com/a/index.html")

  req2 <- req %>% req_url_query(a = 1, b = 2)
  expect_equal(req2$url, "http://example.com/?a=1&b=2")
})
