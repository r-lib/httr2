ttest_that("can throttle requests", {
  skip_on_cran()
  req <- req("https://httpbin.org/get") %>% req_throttle(2 / 1)

  cnd <- req %>% req_fetch() %>% catch_cnd()
  expect_null(cnd)

  cnd <- req %>% req_fetch() %>% catch_cnd()
  expect_s3_class(cnd, "httr2_sleep")
  expect_true(cnd$seconds > 0.1)
})
