test_that("respects httr2 verbosity option", {
  expect_equal(with_verbosity(httr2_verbosity()), 1)

  local({
    local_verbosity(2)
    expect_equal(httr2_verbosity(), 2)
  })
})

test_that("can set httr2 verbosity with env var", {
  withr::local_envvar(HTTR2_VERBOSITY = "1")
  expect_equal(httr2_verbosity(), 1)

  # but option has higher precedence
  withr::local_options(httr2_verbosity = 2)
  expect_equal(httr2_verbosity(), 2)
})

test_that("respects httr verbose config", {
  expect_equal(httr2_verbosity(), 0)

  # Simulate effect of httr::with_verbose(httr2_verbosity())
  config <- list(options = list(debugfunction = identity))
  withr::local_options(httr_config = config)
  expect_equal(httr2_verbosity(), 1)
})
