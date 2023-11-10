test_that("can handle multi query params", {
  expect_equal(
    multi_dots(a = 1:2, .multi = "explode"),
    list(a = I("1"), a = I("2"))
  )
  expect_equal(
    multi_dots(a = 1:2, .multi = "comma"),
    list(a = I("1,2"))
  )
  expect_equal(
    multi_dots(a = 1:2, .multi = "pipe"),
    list(a = I("1|2"))
  )
  expect_equal(
    multi_dots(a = 1:2, .multi = function(x) "X"),
    list(a = I("X"))
  )
})

test_that("can handle empty dots", {
  expect_equal(multi_dots(), list())
})

test_that("preserves NULL values", {
  expect_equal(multi_dots(x = NULL), list(x = NULL))
})

test_that("preserves duplicates values", {
  expect_equal(multi_dots(x = 1, x = 2), list(x = I("1"), x = I("2")))
})

test_that("leaves already escaped values alone", {
  x <- I("1 + 2")
  expect_equal(multi_dots(x = x), list(x = x))
})

test_that("checks its inputs", {
  expect_snapshot(error = TRUE, {
    multi_dots(1)
    multi_dots(x = I(1))
    multi_dots(x = 1:2)
    multi_dots(x = mean)
  })
})
