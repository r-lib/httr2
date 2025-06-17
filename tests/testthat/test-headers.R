test_that("as_headers parses character vector", {
  headers <- as_headers(c("x:1", "y:2", "a", "b:"))
  expect_equal(headers, new_headers(list(x = "1", y = "2", b = "")))
})

test_that("as_headers coerces list", {
  expect_equal(as_headers(list(x = 1)), new_headers(list(x = 1)))
})

test_that("as_headers errors on invalid types", {
  expect_snapshot(error = TRUE, as_headers(1))
})

test_that("has nice print method", {
  expect_snapshot({
    as_headers(c("X:1", "Y: 2", "Z:"))
    as_headers(list())
  })
})

test_that("print and str redact headers", {
  x <- new_headers(list(x = 1, y = 2), redact = "x")
  expect_snapshot({
    print(x)
    str(x)
  })
})

test_that("subsetting is case insensitive", {
  x <- new_headers(list(x = 1))
  expect_equal(x$X, 1)
  expect_equal(x[["X"]], 1)
  expect_equal(x["X"], new_headers(list(x = 1)))
})

test_that("new_headers checks inputs", {
  expect_snapshot(error = TRUE, {
    new_headers(1)
    new_headers(list(1))
    new_headers(list(x = mean))
  })
})

test_that("can flatten repeated inputs", {
  expect_equal(headers_flatten(list()), list())
  expect_equal(headers_flatten(list(x = 1)), list(x = "1"))
  expect_equal(headers_flatten(list(x = 1:2)), list(x = "1,2"))
})

# redaction -------------------------------------------------------------------

test_that("redacted values can't be serialized", {
  path <- withr::local_tempfile()

  headers <- new_headers(list(a = "x", b = "y"), redact = "a")
  saveRDS(headers, path)

  loaded <- readRDS(path)
  expect_equal(headers_flatten(loaded), list(a = redacted_sentinel(), b = "y"))
  expect_equal(headers_flatten(loaded, FALSE), list(b = "y"))
})

test_that("serialized redacted value doesn't cause curl errors", {
  path <- withr::local_tempfile()

  req <- request_test()
  req <- req_auth_basic(req, "user", "password")
  saveRDS(req, path)

  req <- readRDS(path)
  expect_no_error(req_perform(req))
})

test_that("can unredacted values", {
  x <- new_headers(list(x = "x"), redact = "x")
  expect_equal(headers_flatten(x, redact = TRUE), list(x = redacted_sentinel()))
  expect_equal(headers_flatten(x, redact = FALSE), list(x = "x"))
})

test_that("headers can't get double redacted", {
  x1 <- new_headers(list(x = "x"), redact = "x")
  x2 <- new_headers(x1, redact = "x")

  expect_equal(headers_flatten(x2, FALSE), list(x = "x"))
})

test_that("redaction is case-insensitive", {
  headers <- as_headers("AUTHORIZATION: SECRET", redact = "authorization")
  redacted <- headers_flatten(headers)
  expect_named(redacted, "AUTHORIZATION")
  expect_true(is_redacted_sentinel(redacted$AUTHORIZATION))
})
