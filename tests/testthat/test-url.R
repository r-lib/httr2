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
    "http://google.com:80/path?a=1&b=2&c=%7B1%7B2%7D3%7D#frag",
    "http://user@google.com:80/path?a=1&b=2",
    "http://user:pass@google.com:80/path?a=1&b=2",
    "svn+ssh://my.svn.server/repo/trunk"
  )

  expect_equal(map(urls, ~ url_build(url_parse(.x))), urls)
})

test_that("can print all url details", {
  expect_snapshot(
    url_parse("http://user:pass@example.com:80/path?a=1&b=2&c={1{2}3}#frag")
  )
})

test_that("ensures path always starts with /", {
  expect_equal(
    url_modify("https://example.com/abc", path = "def"),
    "https://example.com/def"
  )
})

test_that("password also requires username", {
  url <- url_parse("http://username:pwd@example.com")
  url$username <- NULL
  expect_snapshot(url_build(url), error = TRUE)

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

test_that("validates inputs", {
  expect_snapshot(error = TRUE, {
    query_build(1:3)
    query_build(list(x = 1:2, y = 1:3))
  })
})

# format_query_param ------------------------------------------------------

test_that("handles all atomic vectors", {
  expect_equal(format_query_param(NA), "NA")
  expect_equal(format_query_param(TRUE), "TRUE")
  expect_equal(format_query_param(1L), "1")
  expect_equal(format_query_param(1.3), "1.3")
  expect_equal(format_query_param("x"), "x")
  expect_equal(format_query_param(" "), "%20")
})

test_that("doesn't add extra spaces", {
  expect_equal(format_query_param(c(1, 1000)), c("1", "1000"))
  expect_equal(format_query_param(c("a", "bcdef")), c("a", "bcdef"))
})

test_that("formats numbers nicely", {
  expect_equal(format_query_param(1e9), "1000000000")
})

test_that("can opt out of escaping", {
  expect_equal(format_query_param(I(",")), ",")
})

test_that("can't opt out of escaping non strings", {
  expect_snapshot(format_query_param(I(1)), error = TRUE)
})
