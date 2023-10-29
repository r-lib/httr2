test_that("basic helpers work", {
  reqs <- list(
    request_test("/status/:status", status = 200),
    request_test("/status/:status", status = 404),
    request("INVALID")
  )
  resps <- req_perform_parallel(reqs)

  expect_equal(resps_successes(resps), resps[1])
  expect_equal(resps_failures(resps), resps[2:3])
  expect_equal(resps_requests(resps), reqs)
})

test_that("can extract all data", {
  resps <- list(
    response_json(body = list(data = 1)),
    response_json(body = list(data = 2)),
    response_json(body = list(data = 3))
  )

  expect_equal(
    resps_data(resps, function(resp) resp_body_json(resp)$data),
    1:3
  )
})
