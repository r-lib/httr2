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
  expect_equal(req1$policies$multi$cur_chunk, 1)

  req2 <- chunk_next_request(req1)
  expect_equal(req2$body$data, data.frame(id = 4:5))
  expect_equal(req2$policies$multi$cur_chunk, 2)

  req3 <- chunk_next_request(req2)
  expect_null(req3)
})
