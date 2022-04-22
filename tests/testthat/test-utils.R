test_that("modify list adds, removes, and overrides", {
  x <- list(x = 1)
  expect_equal(modify_list(x), x)
  expect_equal(modify_list(x, x = NULL), list())
  expect_equal(modify_list(x, x = 2), list(x = 2))
  expect_equal(modify_list(x, y = 3), list(x = 1, y = 3))
  expect_equal(modify_list(NULL, x = 2), list(x = 2))

  expect_snapshot(modify_list(x, a = 1, 2), error = TRUE)
})

test_that("`modify_list()` preserves duplicates in `...`", {
  x <- list(x = 1, y = 2)
  expect_equal(modify_list(x, y = 3, y = 4), list(x = 1, y = 3, y = 4))
})

test_that("can check arg types", {
  expect_snapshot(error = TRUE, {
    check_string(1, "x")
    check_number("2", "x")
    check_number(NA_real_, "x")
  })
})
