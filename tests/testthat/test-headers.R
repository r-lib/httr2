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
  expect_snapshot(as_headers(c("X:1", "Y: 2", "Z:")))
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
  })
})
