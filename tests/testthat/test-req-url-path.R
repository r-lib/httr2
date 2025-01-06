test_that("both now deprecated", {
  local_options(lifecycle_verbosity = "warning")
  req <- request("http://example.com/x")

  expect_snapshot({
    . <- req_url_path(req)
    . <- req_url_path_append(req)
  })
})


test_that("automatically adds /", {
  local_options(lifecycle_verbosity = "quiet")

  req1 <- request("http://example.com")
  req2 <- request("http://example.com/")

  expect_equal(req_url_path(req1, "/index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path(req1, "index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path(req2, "/index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path(req2, "index.html")$url, "http://example.com/index.html")

  expect_equal(req_url_path_append(req1, "index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path_append(req1, "/index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path_append(req2, "index.html")$url, "http://example.com/index.html")
  expect_equal(req_url_path_append(req2, "/index.html")$url, "http://example.com/index.html")
})

test_that("can append multiple components", {
  local_options(lifecycle_verbosity = "quiet")

  req <- request("http://example.com/x")
  expect_equal(req_url_path(req, "a", "b")$url, "http://example.com/a/b")
  expect_equal(req_url_path_append(req, "a", "b")$url, "http://example.com/x/a/b")
})

test_that("can handle empty path", {
  local_options(lifecycle_verbosity = "quiet")

  req <- request("http://example.com/x")
  expect_equal(req_url_path(req)$url, "http://example.com/")
  expect_equal(req_url_path_append(req)$url, "http://example.com/x")
  expect_equal(req_url_path(req, NULL)$url, "http://example.com/")
  expect_equal(req_url_path_append(req, NULL)$url, "http://example.com/x")

  expect_equal(req_url_path(req, "")$url, "http://example.com/")
  expect_equal(req_url_path_append(req, "")$url, "http://example.com/x")
})

test_that("can handle path vector", {
  local_options(lifecycle_verbosity = "quiet")

  req <- request("http://example.com/x")
  expect_equal(req_url_path(req, c("a", "b"))$url, "http://example.com/a/b")
  expect_equal(req_url_path_append(req, c("a", "b"))$url, "http://example.com/x/a/b")
  expect_equal(req_url_path_append(req, c("a", "b"), NULL)$url, "http://example.com/x/a/b")
})
