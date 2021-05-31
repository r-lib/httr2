test_that("req_fetch() will throttle requests", {
  throttle_reset()

  req <- req_test("/get") %>% req_throttle(10 / 1)
  cnd <- req %>% req_fetch() %>% catch_cnd()
  expect_null(cnd)

  cnd <- req %>% req_fetch("/get") %>% catch_cnd()
  expect_s3_class(cnd, "httr2_sleep")
  expect_true(cnd$seconds > 0.001)
})
