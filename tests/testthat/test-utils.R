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
  expect_equal(modify_list(x, a = 3, a = 4), list(a = 3, a =4))
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
