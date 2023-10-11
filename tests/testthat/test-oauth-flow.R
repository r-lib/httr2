# oauth_flow_fetch --------------------------------------------------------

test_that("turns oauth errors to R errors", {
  req <- request("http://example.com")
  local_mocked_bindings(req_perform = function(...) {
    response_json(400L, body = list(error = "1", error_description = "abc"))
  })

  expect_snapshot(oauth_flow_fetch(req, "test"), error = TRUE)
})

# oauth_flow_parse --------------------------------------------------------

test_that("userful errors if response isn't parseable", {
  resp1 <- response(headers = list(`content-type` = "text/plain"))
  resp2 <- response_json(body = list())

  expect_snapshot(error = TRUE, {
    oauth_flow_parse(resp1, "test")
    oauth_flow_parse(resp2, "test")
  })
})

test_that("returns body if known good structure", {
  resp <- response_json(body = list(access_token = "10"))
  expect_equal(oauth_flow_parse(resp, "test"), list(access_token = "10"))

  resp <- response_json(body = list(device_code = "10"))
  expect_equal(oauth_flow_parse(resp, "test"), list(device_code = "10"))

  resp <- response_json(403L, body = list(error = "10"))
  expect_snapshot(oauth_flow_parse(resp, "test"), error = TRUE)
})

test_that("converts expires_in to numeric", {
  resp <- response_json(200L, body = list(access_token = "10", expires_in = "20"))
  body <- oauth_flow_parse(resp, "test")
  expect_equal(body$expires_in, 20)
})

