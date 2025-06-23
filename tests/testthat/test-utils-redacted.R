test_that("sentinel displays nicely", {
  x <- redacted_sentinel()

  expect_snapshot({
    x
    format(x)
    str(x)
  })
})

test_that("can redact named components of a list", {
  x <- list(a = 1, b = 2, c = 3)
  expect_equal(list_redact(x, "a"), list(a = redacted_sentinel(), b = 2, c = 3))
})
