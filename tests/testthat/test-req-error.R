test_that("can customise what statuses are errors", {
  req <- request_test()
  expect_equal(error_is_error(req, response(404)), TRUE)
  expect_equal(error_is_error(req, response(200)), FALSE)

  req <- req |> req_error(is_error = \(resp) !resp_is_error(resp))
  expect_equal(error_is_error(req, response(404)), FALSE)
  expect_equal(error_is_error(req, response(200)), TRUE)
})

test_that("can customise error info", {
  req <- request_test("/404")
  expect_equal(error_body(req, response(404)), NULL)

  req <- req |> req_error(body = \(resp) "Hi!")
  expect_equal(error_body(req, response(404)), "Hi!")

  expect_snapshot(req_perform(req), error = TRUE)
})

test_that("long custom body is wrapped", {
  withr::local_options(cli.condition_width = 60)

  body <- paste0(
    "Ad aliquip et occaecat consequat eiusmod enim Lorem incididunt laboris ",
    "deserunt. Consectetur magna ea ad quis dolore. Deserunt elit elit dolore ",
    "magna fugiat ipsum id eu nostrud voluptate Lorem ad id anim. Cupidatat ",
    "nulla ipsum irure nisi sunt ipsum commodo eu sint eiusmod consectetur."
  )
  req <- request("http://google.com") |>
    req_error(is_error = \(resp) TRUE, body = \(resp) body)
  expect_snapshot(req_perform(req), error = TRUE)
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
