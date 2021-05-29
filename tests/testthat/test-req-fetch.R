test_that("can throttle requests", {
  skip_on_cran()

  the$throttle[["httpbin.org"]] <- NULL

  req1 <- req("https://httpbin.org/get") %>% req_throttle(2 / 1)
  req2 <- req("https://httpbin.org/get") %>% req_throttle(2 / 1)

  cnd <- req1 %>% req_fetch() %>% catch_cnd()
  expect_null(cnd)

  cnd <- req1 %>% req_fetch() %>% catch_cnd()
  expect_s3_class(cnd, "httr2_sleep")
  expect_true(cnd$seconds > 0.1)

  # Shared state with other request
  cnd <- req2 %>% req_fetch() %>% catch_cnd()
  expect_s3_class(cnd, "httr2_sleep")
  expect_true(cnd$seconds > 0.1)
})
