test_that("can retrieve last request and response", {
  req <- request_test()
  resp <- req_perform(req)

  expect_equal(last_request(), req)
  expect_equal(last_response(), resp)
})

test_that("last response is NULL if it fails", {
  req <- request("")
  try(req_perform(req), silent = TRUE)

  expect_equal(last_request(), req)
  expect_equal(last_response(), NULL)
})

test_that("returns NULL if no last request/response", {
  the$last_request <- NULL
  the$last_response <- NULL

  expect_equal(last_request(), NULL)
  expect_equal(last_response(), NULL)
})

# JSON -----------------------------------------------------------------------

test_that("can get json response", {
  req <- local_app_request(function(req, res) {
    res$set_status(200L)$send_json(text = '{"x":1}')
  })
  req_perform(req)

  expect_snapshot({
    last_response_json()
    last_response_json(pretty = FALSE)
  })
})

test_that("can get json request", {
  request(example_url("/post")) |>
    req_body_json(list(x = 1)) |>
    req_perform()

  expect_snapshot({
    last_request_json()
    last_request_json(pretty = FALSE)
  })
})

test_that("useful errors if not json request/response", {
  req_perform(request(example_url("/xml")))

  expect_snapshot(error = TRUE, {
    last_request_json()
    last_response_json()
  })
})

test_that("useful errors if no last request/response", {
  the$last_request <- NULL
  the$last_response <- NULL

  expect_snapshot(error = TRUE, {
    last_request_json()
    last_response_json()
  })
})
