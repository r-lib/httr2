test_that("as_callback validates inputs", {
  expect_snapshot(as_callback(function(x) 2, 2, "foo"), error = TRUE)
})
