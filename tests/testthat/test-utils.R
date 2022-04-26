test_that("modify list adds, removes, and overrides", {
  x <- list(x = 1)
  expect_equal(modify_list_dots(x), x)
  expect_equal(modify_list_dots(x, x = NULL), list())
  expect_equal(modify_list_dots(x, x = 2), list(x = 2))
  expect_equal(modify_list_dots(x, y = 3), list(x = 1, y = 3))
  expect_equal(modify_list_dots(NULL, x = 2), list(x = 2))

  expect_snapshot(modify_list_dots(x, a = 1, 2), error = TRUE)
})

test_that("replacement affects all components with name", {
  x <- list(a = 1, a = 2)
  expect_equal(modify_list_dots(x, a = NULL), list())
  expect_equal(modify_list_dots(x, a = 3), list(a = 3))
  expect_equal(modify_list_dots(x, a = 3, a = 4), list(a = 3, a =4))
})

test_that("can check arg types", {
  expect_snapshot(error = TRUE, {
    check_string(1, "x")
    check_number("2", "x")
    check_number(NA_real_, "x")
  })
})
