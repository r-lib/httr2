test_that("can override url", {
  req <- request("http://example.com/")
  expect_equal(req_url(req, "http://foo.com:10")$url, "http://foo.com:10")
})

test_that("automatically adds /", {
  req1 <- request("http://example.com")
  req2 <- request("http://example.com/")

  expect_equal(req_url_path(req1, "/index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path(req1, "index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path(req2, "/index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path(req2, "index.html")$url, "http://example.com/index.html")

  expect_equal(req_url_path_append(req1, "index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path_append(req1, "/index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path_append(req2, "index.html")$url, "http://example.com/index.html")
  # specifically requested to add in both
  expect_equal(req_url_path_append(req2, "/index.html")$url, "http://example.com//index.html")
})

test_that("can set query params", {
  req <- request("http://example.com/")
  expect_equal(req_url_query(req, a = 1, b = 2)$url, "http://example.com/?a=1&b=2")
  expect_equal(req_url_query(req, a = 1, b = 2, c = NULL)$url, "http://example.com/?a=1&b=2")
  expect_equal(req_url_query(req, !!!list(a = 1, b = 2))$url, "http://example.com/?a=1&b=2")
})
