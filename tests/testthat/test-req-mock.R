test_that("can override requests with local_ or with_", {
  req <- request("https://google.com")
  resp <- response()

  with_mocked_responses(\(req) resp, {
    expect_equal(req_perform(req), resp)
  })

  local_mocked_responses(\(req) resp)
  expect_equal(req_perform(req), resp)
})

test_that("local_mock and with_mock are deprecated", {
  expect_snapshot(error = TRUE, {
    local_mock(\(req) response(404))
    . <- with_mock(NULL, \(req) response(404))
  })
})

test_that("mocked_response_sequence returns responses then errors", {
  local_mocked_responses(list(
    response(200),
    response(201)
  ))

  req <- request("https://google.com")
  expect_equal(req_perform(req), response(200))
  expect_equal(req_perform(req), response(201))
  expect_error(req_perform(req), class = "httr2_http_503")
})

test_that("validates inputs", {
  expect_snapshot(error = TRUE, {
    local_mocked_responses(function(foo) {})
    local_mocked_responses(10)
  })
})
