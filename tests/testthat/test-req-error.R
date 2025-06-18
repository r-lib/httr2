test_that("can customise what statuses are errors", {
  req <- request_test()
  expect_equal(error_is_error(req, response(404)), TRUE)
  expect_equal(error_is_error(req, response(200)), FALSE)

  req <- req |> req_error(is_error = \(resp) !resp_is_error(resp))
  expect_equal(error_is_error(req, response(404)), FALSE)
  expect_equal(error_is_error(req, response(200)), TRUE)
})

test_that("can customise error info", {
  req <- request_test()
  expect_equal(error_body(req, response(404)), NULL)

  req <- req |> req_error(body = \(resp) "Hi!")
  expect_equal(error_body(req, response(404)), "Hi!")
})

test_that("failing callback still generates useful body", {
  req <- request_test() |> req_error(body = \(resp) abort("This is an error!"))
  expect_snapshot_error(error_body(req, response(404)))

  out <- expect_snapshot(error = TRUE, {
    req <- request_test("/status/404")
    req <- req |> req_error(body = \(resp) resp_body_json(resp)$error)
    req |> req_perform()
  })
})
