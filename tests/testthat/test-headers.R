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

test_that("redaction is case-insensitive", {
  headers <- as_headers("AUTHORIZATION: SECRET")
  attr(headers, "redact") <- "Authorization"
  redacted <- headers_redact(headers)
  expect_named(redacted, "AUTHORIZATION")
  expect_true(is_redacted(redacted$AUTHORIZATION))
})

test_that("new_headers checks inputs", {
  expect_snapshot(error = TRUE, {
    new_headers(1)
    new_headers(list(1))
  })
})

test_that("can flatten repeated inputs", {
  expect_equal(headers_flatten(list()), list())
  expect_equal(headers_flatten(list(x = 1)), list(x = "1"))
  expect_equal(headers_flatten(list(x = 1:2)), list(x = "1,2"))
})

test_that("redacted inputs are preserved", {
  x <- new_headers(list(x = "x"), redact = "x")
  expect_equal(headers_flatten(x), x)
})
