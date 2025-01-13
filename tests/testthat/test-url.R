test_that("can parse special cases", {
  url <- url_parse("file:///tmp")
  expect_equal(url$scheme, "file")
  expect_equal(url$path, "/tmp")
})

test_that("can round trip urls", {
  urls <- list(
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

test_that("can parse relative urls", {
  base <- "http://example.com/a/b/c/"
  expect_equal(url_parse("d", base)$path, "/a/b/c/d")
  expect_equal(url_parse("..", base)$path, "/a/b/")

  expect_equal(url_parse("//archive.org", base)$scheme, "http")
})

test_that("can print all url details", {
  expect_snapshot(
    url_parse("http://user:pass@example.com:80/path?a=1&b=2&c={1{2}3}#frag")
  )
})

test_that("password also requires username", {
  url <- url_parse("http://username:pwd@example.com")
  url$username <- NULL
  expect_snapshot(url_build(url), error = TRUE)
})

test_that("url_build validates its input", {
  expect_snapshot(url_build("abc"), error = TRUE)
})

test_that("decodes query params but not paths", {
  url <- url_parse("http://example.com/a%20b?q=a%20b")
  expect_equal(url$path, "/a%20b")
  expect_equal(url$query$q, "a b")
})

# modify url -------------------------------------------------------------

test_that("url_modify checks its inputs", {
  url <- "http://example.com"

  expect_snapshot(error = TRUE, {
    url_modify(1)
    url_modify(url, scheme = 1)
    url_modify(url, hostname = 1)
    url_modify(url, port = "x")
    url_modify(url, username = 1)
    url_modify(url, password = 1)
    url_modify(url, path = 1)
    url_modify(url, fragment = 1)
  })
})

test_that("no arguments is idempotent", {
  string <- "http://example.com/"
  url <- url_parse(string)

  expect_equal(url_modify(string), string)
  expect_equal(url_modify(url), url)
})

test_that("can round-trip escaped components", {
  url <- "https://example.com/a%20b"
  expect_equal(url_modify(url), url)

  url <- "https://example.com/?q=a%20b"
  expect_equal(url_modify(url), url)
})

test_that("can accept query as a string or list", {
  url <- "http://test/"

  expect_equal(url_modify(url, query = "a=1&b=2"), "http://test/?a=1&b=2")
  expect_equal(url_modify(url, query = list(a = 1, b = 2)), "http://test/?a=1&b=2")

  expect_equal(url_modify(url, query = ""), "http://test/")
  expect_equal(url_modify(url, query = list()), "http://test/")
})

test_that("automatically escapes query components", {
  expect_equal(
    url_modify("https://example.com", query = list(q = "a b")),
    "https://example.com/?q=a%20b"
  )
})

test_that("checks various query formats", {
  url <- "http://example.com"

  expect_snapshot(error = TRUE, {
    url_modify(url, query = 1)
    url_modify(url, query = list(1))
    url_modify(url, query = list(x = 1:2))
  })
})

test_that("path always starts with /", {
  expect_equal(url_modify("https://x.com/abc", path = "def"), "https://x.com/def")
  expect_equal(url_modify("https://x.com/abc", path = ""), "https://x.com/")
  expect_equal(url_modify("https://x.com/abc", path = NULL), "https://x.com/")
})

# relative url ------------------------------------------------------------

test_that("can set relative urls", {
  base <- "http://example.com/a/b/c/"
  expect_equal(url_modify_relative(base, "d"), "http://example.com/a/b/c/d")
  expect_equal(url_modify_relative(base, ".."), "http://example.com/a/b/")
  expect_equal(url_modify_relative(base, "//archive.org"), "http://archive.org/")
})

test_that("is idempotent", {
  string <- "http://example.com/"
  url <- url_parse(string)

  expect_equal(url_modify_relative(string, "."), string)
  expect_equal(url_modify_relative(url, "."), url)
})

# modify query -------------------------------------------------------------

test_that("can add, modify, and delete query components", {
  expect_equal(
    url_modify_query("http://test/path", new = "value"),
    "http://test/path?new=value"
  )
  expect_equal(
    url_modify_query("http://test/path", new = "one", new = "two"),
    "http://test/path?new=one&new=two"
  )
  expect_equal(
    url_modify_query("http://test/path?a=old&b=old", a = "new"),
    "http://test/path?b=old&a=new"
  )
  expect_equal(
    url_modify_query("http://test/path?remove=me&keep=this", remove = NULL),
    "http://test/path?keep=this"
  )
})

test_that("can control space formatting", {
  expect_equal(
    url_modify_query("http://test/path", new = "a b"),
    "http://test/path?new=a%20b"
  )
  expect_equal(
    url_modify_query("http://test/path", new = "a b", .space = "form"),
    "http://test/path?new=a+b"
  )
})

test_that("is idempotent", {
  string <- "http://example.com/"
  url <- url_parse(string)

  expect_equal(url_modify_query(string), string)
  expect_equal(url_modify_query(url), url)
})

test_that("validates inputs", {
  url <- "http://example.com/"

  expect_snapshot(error = TRUE, {
    url_modify_query(1)
    url_modify_query(url, 1)
    url_modify_query(url, x = 1:2)
  })
})


# query -------------------------------------------------------------------

test_that("missing query values become empty strings", {
  expect_equal(url_query_parse("?q="), list(q = ""))
  expect_equal(url_query_parse("?q"), list(q = ""))
  expect_equal(url_query_parse("?a&q"), list(a = "", q = ""))
})

test_that("handles equals in values", {
  expect_equal(url_query_parse("?x==&y=="), list(x = "=", y = "="))
})

test_that("empty queries become NULL", {
  expect_equal(url_query_parse("?"), NULL)
  expect_equal(url_query_parse(""), NULL)
})

test_that("validates inputs", {
  expect_snapshot(error = TRUE, {
    url_query_build(1:3)
    url_query_build(list(x = 1:2, y = 1:3))
  })
})

# format_query_param ------------------------------------------------------

test_that("handles all atomic vectors", {
  expect_equal(format_query_param(NA, "x"), "NA")
  expect_equal(format_query_param(TRUE, "x"), "TRUE")
  expect_equal(format_query_param(1L, "x"), "1")
  expect_equal(format_query_param(1.3, "x"), "1.3")
  expect_equal(format_query_param("x", "x"), "x")
  expect_equal(format_query_param(" ", "x"), "%20")
})

test_that("doesn't add extra spaces", {
  expect_equal(
    format_query_param(c(1, 1000), "x", multi = TRUE),
    c("1", "1000")
  )
  expect_equal(
    format_query_param(c("a", "bcdef"), multi = TRUE, "x"),
    c("a", "bcdef")
  )
})

test_that("formats numbers nicely", {
  expect_equal(format_query_param(1e9, "x"), "1000000000")
})

test_that("can opt out of escaping", {
  expect_equal(format_query_param(I(","), "x"), ",")
})

test_that("can't opt out of escaping non strings", {
  expect_snapshot(format_query_param(I(1), "x"), error = TRUE)
})
