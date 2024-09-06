test_that("modify list adds, removes, and overrides", {
  x <- list(x = 1)
  expect_equal(modify_list(x), x)
  expect_equal(modify_list(x, x = NULL), list())
  expect_equal(modify_list(x, x = 2), list(x = 2))
  expect_equal(modify_list(x, y = 3), list(x = 1, y = 3))
  expect_equal(modify_list(NULL, x = 2), list(x = 2))

  expect_snapshot(modify_list(x, a = 1, 2), error = TRUE)
})

test_that("replacement affects all components with name", {
  x <- list(a = 1, a = 2)
  expect_equal(modify_list(x, a = NULL), list())
  expect_equal(modify_list(x, a = 3), list(a = 3))
  expect_equal(modify_list(x, a = 3, a = 4), list(a = 3, a = 4))
})

test_that("respects httr2 verbosity option", {
  expect_equal(with_verbosity(httr2_verbosity()), 1)
})

test_that("respects httr verbose config", {
  expect_equal(httr2_verbosity(), 0)

  # Simulate effect of httr::with_verbose(httr2_verbosity())
  config <- list(options = list(debugfunction = identity))
  withr::local_options(httr_config = config)
  expect_equal(httr2_verbosity(), 1)
})

test_that("progress bar suppressed in tests", {
  expect_snapshot(sys_sleep(0.1, "in test"))
})


test_that("has a working slice", {
  x <- letters[1:5]
  expect_identical(slice(x), x)
  expect_identical(slice(x, 1, length(x) + 1), x)

  # start is inclusive, end is exclusive
  expect_identical(slice(x, 1, length(x)), head(x, -1))
  # zero-length slices are fine
  expect_identical(slice(x, 1, 1), character())
  # starting off the end is fine
  expect_identical(slice(x, length(x) + 1), character())
  expect_identical(slice(x, length(x) + 1, length(x) + 1), character())
  # slicing zero-length is fine
  expect_identical(slice(character()), character())

  # out of bounds
  expect_error(slice(x, 0, 1))
  expect_error(slice(x, length(x) + 2))
  expect_error(slice(x, end = length(x) + 2))
  # end too small relative to start
  expect_error(slice(x, 2, 1))
})
