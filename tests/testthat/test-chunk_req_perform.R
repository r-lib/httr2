test_that("chunk_next_request() can chunk a request", {
  apply_chunk <- function(req, chunk) {
    req_body_json(req, chunk)
  }

  req <- req_chunk(
    request("http://example.com"),
    chunk_size = 3,
    data = data.frame(id = 1:5),
    apply_chunk = apply_chunk
  )

  req1 <- chunk_next_request(req)
  expect_equal(req1$body$data, data.frame(id = 1:3))
  expect_equal(req1$policies$chunk$cur_chunk, 1)

  req2 <- chunk_next_request(req1)
  expect_equal(req2$body$data, data.frame(id = 4:5))
  expect_equal(req2$policies$chunk$cur_chunk, 2)

  req3 <- chunk_next_request(req2)
  expect_null(req3)
})

test_that("chunk_req_perform() performs a request in chunks", {
  apply_chunk <- function(req, chunk) {
    req_body_json(req, chunk)
  }

  local_mocked_responses(list(
    response_json(body = data.frame(id = 1:3)),
    response_json(body = data.frame(id = 4:5))
  ))

  req <- req_chunk(
    request("http://example.com"),
    chunk_size = 3,
    data = data.frame(id = 1:5),
    apply_chunk = apply_chunk,
    parse_resp = function(resp) resp_body_json(resp, simplifyVector = TRUE)
  )

  responses <- chunk_req_perform(req)
  expect_equal(
    responses,
    list(data.frame(id = 1:3), data.frame(id = 4:5))
  )

  req <- req_chunk(
    request("http://example.com"),
    chunk_size = 3,
    data = data.frame(id = integer()),
    apply_chunk = apply_chunk,
    parse_resp = function(resp) resp_body_json(resp, simplifyVector = TRUE)
  )

  responses <- chunk_req_perform(req)
  expect_equal(responses, list())
})
