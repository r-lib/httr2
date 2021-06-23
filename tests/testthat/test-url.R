test_that("can parse special cases", {
  url <- url_parse("//google.com")
  expect_equal(url$scheme, NULL)
  expect_equal(url$hostname, "google.com")

  url <- url_parse("file:///tmp")
  expect_equal(url$scheme, "file")
  expect_equal(url$path, "/tmp")

  url <- url_parse("/")
  expect_equal(url$scheme, NULL)
  expect_equal(url$path, "/")
})

test_that("can round trip urls", {
  urls <- list(
    "/",
    "//google.com",
    "file:///",
    "http://google.com/",
    "http://google.com/path",
    "http://google.com/path?a=1&b=2",
    "http://google.com:80/path?a=1&b=2",
    "http://google.com:80/path?a=1&b=2#frag",
    "http://user@google.com:80/path?a=1&b=2",
    "http://user:pass@google.com:80/path?a=1&b=2",
    "svn+ssh://my.svn.server/repo/trunk"
  )

  expect_equal(map(urls, ~ url_build(url_parse(.x))), urls)
})

test_that("can print all url details", {
  expect_snapshot(
    url_parse("http://user:pass@example.com:80/path?a=1&b=2#frag")
  )
})

# query -------------------------------------------------------------------

test_that("missing query values become empty strings", {
  expect_equal(query_parse("?q="), list(q = ""))
  expect_equal(query_parse("?q"), list(q = ""))
  expect_equal(query_parse("?a&q"), list(a = "", q = ""))
})

test_that("empty queries become NULL", {
  expect_equal(query_parse("?"), NULL)
  expect_equal(query_parse(""), NULL)
})

