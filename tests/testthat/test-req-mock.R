test_that("can override requests with local_ or with_", {
  req <- request("https://google.com")
  resp <- response()
  expected <- resp
  expected$request <- req

  with_mocked_responses(\(req) resp, {
    expect_equal(req_perform(req), expected)
  })

  local_mocked_responses(\(req) resp)
  expect_equal(req_perform(req), expected)
})

test_that("mocked responses include the request", {
  req <- request("https://google.com")
  local_mocked_responses(\(req) response())

  expect_equal(req_perform(req)$request, req)
})

test_that("mocked_response_sequence returns responses then errors", {
  local_mocked_responses(list(
    response(200),
    response(201)
  ))

  req <- request("https://google.com")
  expect_equal(req_perform(req)$status_code, 200)
  expect_equal(req_perform(req)$status_code, 201)
  expect_error(req_perform(req), class = "httr2_http_503")
})

test_that("validates inputs", {
  expect_snapshot(error = TRUE, {
    local_mocked_responses(function(foo) {})
    local_mocked_responses(10)
  })
})
