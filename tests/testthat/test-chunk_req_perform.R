test_that("vec_chop_by_size() can chop into chunks", {
  expect_equal(vec_chop_by_size(1:6, 3), list(1:3, 4:6))
  # can create a partial chunk
  expect_equal(vec_chop_by_size(1:5, 3), list(1:3, 4:5))
  # works if chunk_size bigger than x
  expect_equal(vec_chop_by_size(1:5, 10), list(1:5))
  # works with empty input
  expect_equal(vec_chop_by_size(character(), 10), list())

  expect_snapshot(error = TRUE, {
    chunk_size <- 1.5
    vec_chop_by_size(1:5, chunk_size)
  })
})

test_that("req_chunk() can chunk a request", {
  apply_chunk <- function(req, chunk) {
    req_body_json(req, chunk)
  }

  req <- request("http://example.com")
  requests <- req_chunk(
    req,
    chunk_size = 3,
    data = data.frame(id = 1:5),
    apply_chunk = apply_chunk
  )

  expect_length(requests, 2)
  expect_equal(requests[[1]], req %>% req_body_json(data.frame(id = 1:3)))
  expect_equal(requests[[2]], req %>% req_body_json(data.frame(id = 4:5)))
})

test_that("chunk_req_perform() performs a request in chunks", {
  apply_chunk <- function(req, chunk) {
    req_body_json(req, chunk)
  }

  local_mocked_responses(list(
    response_json(body = data.frame(id = 1:3)),
    response_json(body = data.frame(id = 4:5))
  ))

  req <- request("http://example.com")
  responses <- chunk_req_perform(
    req,
    chunk_size = 3,
    data = data.frame(id = 1:5),
    apply_chunk = apply_chunk,
    parse_resp = function(resp) resp_body_json(resp, simplifyVector = TRUE)
  )

  expect_equal(
    responses,
    list(data.frame(id = 1:3), data.frame(id = 4:5))
  )

  req <- request("http://example.com")
  responses <- chunk_req_perform(
    req,
    chunk_size = 3,
    data = data.frame(id = integer()),
    apply_chunk = apply_chunk,
    parse_resp = function(resp) resp_body_json(resp, simplifyVector = TRUE)
  )

  expect_equal(responses, list())
})
