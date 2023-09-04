test_that("can override requests through mocking", {
  resp <- response()
  req <- request("https://google.com")

  expect_equal(with_mocked_responses(~ resp, req_perform(req)), resp)

  local_mocked_responses(~ resp)
  expect_equal(req_perform(req), resp)
})

test_that("can generate errors with mocking", {
  local_mocked_responses(~ response(404))

  req <- request("https://google.com")
  expect_error(req_perform(req), class = "httr2_http_404")
})

test_that("local_mock and with_mock are deprecated", {
  expect_snapshot({
    local_mock(~ response(404))
    . <- with_mock(NULL, ~ response(404))
  })
})
