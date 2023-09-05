
# oauth_flow_fetch --------------------------------------------------------

test_that("errors if response isn't json", {
  req <- request("http://example.com")
  local_mocked_bindings(req_perform = function(...) {
    response(200L, headers = list(`content-type` = "text/plain"))
  })

  expect_snapshot(oauth_flow_fetch(req), error = TRUE)
})

test_that("forwards turns oauth errors to R errors", {
  req <- request("http://example.com")
  body <- list(error = "1", error_description = "abc")
  local_mocked_bindings(req_perform = function(...) {
    response_json(200L, body = body)
  })

  expect_snapshot(oauth_flow_fetch(req), error = TRUE)
})


test_that("returns body if successful", {
  req <- request("http://example.com")
  local_mocked_bindings(req_perform = function(...) {
    response_json(200L, body = list(access_token = "10", expires_in = "20"))
  })

  expect_equal(
    oauth_flow_fetch(req),
    list(access_token = "10", expires_in = 20)
  )
})
