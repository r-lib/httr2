test_that("can add and remove headers", {
  req <- request("http://example.com")
  req <- req |> req_headers(x = 1)
  expect_equal(req$headers, new_headers(list(x = 1)))
  req <- req |> req_headers(x = NULL)
  expect_equal(req$headers, new_headers(list()))
})

test_that("simple vectors automatically converted to strings", {
  req <- request("http://example.com")
  req <- req |> req_headers(lgl = TRUE, int = 1L, dbl = 1.1, chr = "a")
  resp <- req_dry_run(req, quiet = TRUE)

  expect_equal(resp$headers$lgl, "TRUE")
  expect_equal(resp$headers$int, "1")
  expect_equal(resp$headers$dbl, "1.1")
  expect_equal(resp$headers$chr, "a")
})

test_that("bad inputs get clear error", {
  req <- request("http://example.com")
  expect_snapshot(error = TRUE, {
    req_headers(req, fun = mean)
    req_headers(req, 1)
  })
})

test_that("can add header called req", {
  req <- request("http://example.com")
  req <- req |> req_headers(req = 1)
  expect_equal(req$headers, new_headers(list(req = 1)))
})

test_that("can add repeated headers", {
  resp <- request_test() |>
    req_headers(a = c("a", "b")) |>
    req_dry_run(quiet = TRUE)
  # https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.2
  expect_equal(resp$headers$a, "a,b")
})

test_that("replacing headers is case-insensitive", {
  req <- request("http://example.com")
  req <- req |> req_headers(A = 1)
  req <- req |> req_headers(a = 2)
  expect_equal(req$headers, new_headers(list(a = 2)))
})

# accessor ----------------------------------------------------------------

test_that("can control redaction", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, b = 2L, .redact = "a")

  expect_equal(req_get_headers(req, "drop"), list(b = "2"))
  expect_equal(req_get_headers(req, "redact"), list(a = "<REDACTED>", b = "2"))
  expect_equal(req_get_headers(req, "reveal"), list(a = "1", b = "2"))
})

test_that("empty redacted headers are always dropped", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, b = 2L, .redact = "a")
  req2 <- unserialize(serialize(req, NULL))

  expect_equal(req_get_headers(req2, "drop"), list(b = "2"))
  expect_equal(req_get_headers(req2, "redact"), list(b = "2"))
  expect_equal(req_get_headers(req2, "reveal"), list(b = "2"))
})

# redaction ---------------------------------------------------------------

test_that("can control which headers to redact", {
  req <- request("http://example.com")
  expect_redacted(req_headers(req, a = 1L, b = 2L), character())
  expect_redacted(req_headers(req, a = 1L, b = 2L, .redact = "a"), "a")
  expect_redacted(
    req_headers(req, a = 1L, b = 2L, .redact = c("a", "b")),
    c("a", "b")
  )
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
  expect_equal(headers_flatten(req$headers, FALSE), list(a = "2"))

  # and is reapplied regadless of case
  req <- req_headers(req, A = 3)
  expect_redacted(req, "A")
  expect_equal(headers_flatten(req$headers, FALSE), list(A = "3"))
})

test_that("req_headers_redacted redacts all headers", {
  req <- request("http://example.com")
  expect_redacted(req_headers_redacted(req, a = 1L, b = 2L), c("a", "b"))
})

test_that("is case insensitive", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, .redact = "A")
  expect_redacted(req, "a")
  expect_snapshot(req)

  # Test the other direction too, just to be safe
  req <- request("http://example.com")
  req <- req_headers(req, A = 1L, .redact = "a")
  expect_redacted(req, "A")
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
