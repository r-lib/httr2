test_that("req_perform_multi() checks inputs", {
  req <- request("http://example.com") %>%
    req_paginate_token(
      set_token = function(req, token) {
        req_body_json(req, list(my_token = token))
      },
      next_token = function(resp, parsed) {
        1
      }
    )

  expect_snapshot(error = TRUE, {
    req_perform_multi("a")
    req_perform_multi(request("http://example.com"))
    req_perform_multi(req, max_requests = 0)
    req_perform_multi(req, progress = -1)
  })
})

test_that("req_perform_multi() iterates through pages", {
  req <- request_pagination_test()

  responses_2 <- req_perform_multi(req, max_requests = 2)
  expect_length(responses_2, 2)
  expect_equal(responses_2[[1]], token_body_test(2))
  expect_equal(responses_2[[2]], token_body_test(3))

  responses_5 <- req_perform_multi(req, max_requests = 5)
  expect_length(responses_5, 4)
  expect_equal(responses_5[[4]], token_body_test())

  responses_inf <- req_perform_multi(req, max_requests = Inf)
  expect_length(responses_inf, 4)
  expect_equal(responses_inf[[4]], token_body_test())
})

test_that("req_perform_multi() works if there is only one page", {
  req <- request_pagination_test(n_pages = function(resp, parsed) 1)

  expect_no_error(responses <- req_perform_multi(req, max_requests = 2))
  expect_length(responses, 1)
})

test_that("req_perform_multi() handles error in `parse_resp()`", {
  req <- request_pagination_test(
    parse_resp = function(resp) {
      parsed <- resp_body_json(resp)
      if (parsed$my_next_token >= 2) {
        abort("error")
      }
    }
  )

  expect_snapshot(error = TRUE, {
    req_perform_multi(req, max_requests = 2)
  })
})

test_that("req_perform_multi() performs a request in chunks", {
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

  responses <- req_perform_multi(req)
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

  responses <- req_perform_multi(req)
  expect_equal(responses, list())
})
