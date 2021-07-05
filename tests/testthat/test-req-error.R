test_that("can customise what statuses are errors", {
  req <- request_test()
  expect_equal(error_is_error(req, response(404)), TRUE)
  expect_equal(error_is_error(req, response(200)), FALSE)

  req <- req %>% req_error(is_error = ~ !resp_is_error(.x))
  expect_equal(error_is_error(req, response(404)), FALSE)
  expect_equal(error_is_error(req, response(200)), TRUE)
})

test_that("can customise error info", {
  req <- request_test()
  expect_equal(error_info(req, response(404)), NULL)

  req <- req %>% req_error(info = ~ "Hi!")
  expect_equal(error_info(req, response(404)), "Hi!")
})
