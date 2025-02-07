test_that("can add and remove headers", {
  req <- request("http://example.com")
  req <- req %>% req_headers(x = 1)
  expect_equal(req$headers, structure(list(x = 1), redact = character()))
  req <- req %>% req_headers(x = NULL)
  expect_equal(req$headers, structure(list(), redact = character()))
})

test_that("can add header called req", {
  req <- request("http://example.com")
  req <- req %>% req_headers(req = 1)
  expect_equal(req$headers, structure(list(req = 1), redact = character()))
})

test_that("can add repeated headers", {
  resp <- request_test() %>%
    req_headers(a = c("a", "b")) %>%
    req_dry_run(quiet = TRUE)
  # https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.2
  expect_equal(resp$headers$a, c("a,b"))
})

# redaction ---------------------------------------------------------------

test_that("can control which headers to redact", {
  req <- request("http://example.com")
  expect_redacted(req_headers(req, a = 1L, b = 2L), character())
  expect_redacted(req_headers(req, a = 1L, b = 2L, .redact = "a"), "a")
  expect_redacted(req_headers(req, a = 1L, b = 2L, .redact = c("a", "b")), c("a", "b"))
})

test_that("only redacts supplied headers", {
  req <- request("http://example.com")
  expect_redacted(req_headers(req, a = 1L, b = 2L, .redact = "d"), character())
})

test_that("redaction preserved across calls", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, .redact = "a")
  req <- req_headers(req, a = 2)
  expect_redacted(req, "a")
})

test_that("req_headers_redacted redacts all headers", {
  req <- request("http://example.com")
  expect_redacted(req_headers_redacted(req, a = 1L, b = 2L), c("a", "b"))
})

test_that("is case insensitive", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, .redact = "A")
  expect_redacted(req, "A")
  expect_snapshot(req)
})

test_that("authorization is always redacted", {
  req <- request("http://example.com")
  expect_redacted(req_headers(req, Authorization = "X"), "Authorization")
})

test_that("checks input types", {
  req <- request("http://example.com")
  expect_snapshot(error = TRUE, {
    req_headers(req, a = 1L, b = 2L, .redact = 1L)
  })
})
