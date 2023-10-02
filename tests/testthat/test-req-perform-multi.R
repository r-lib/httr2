test_that("req_perform_multi() checks inputs", {
  req <- request("http://example.com") %>%
    req_paginate_token(
      parse_resp = function(resp) {
        list(next_token = 1, data = "a")
      },
      set_token = function(req, next_token) {
        req_body_json(req, list(my_token = next_token))
      }
    )

  expect_snapshot(error = TRUE, {
    req_perform_multi("a")
    req_perform_multi(request("http://example.com"))
    req_perform_multi(req, path = 3)
    req_perform_multi(req, path = "abc")
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

      list(next_token = parsed$my_next_token, data = parsed)
    }
  )

  skip("decide what to do if some requests error")
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
  expect_equal(responses, data.frame(id = 1:5))

  req <- req_chunk(
    request("http://example.com"),
    chunk_size = 3,
    data = data.frame(id = integer()),
    apply_chunk = apply_chunk,
    parse_resp = function(resp) resp_body_json(resp, simplifyVector = TRUE)
  )

  responses <- req_perform_multi(req)
  expect_equal(responses, NULL)
})

test_that("req_perform_multi() can store response in path", {
  path <- withr::local_tempfile(pattern = "resp_%i_")

  apply_chunk <- function(req, chunk) {
    req_body_json(req, chunk)
  }

  req <- req_chunk(
    request_test("/post"),
    chunk_size = 3,
    data = data.frame(id = 1:5),
    apply_chunk = apply_chunk
  )

  responses <- req_perform_multi(req, path = path)
  expect_equal(responses[[1]]$body, new_path(sub("%i", 1, path, fixed = TRUE)))
  expect_equal(responses, data.frame(id = 1:5))

  req <- req_chunk(
    request("http://example.com"),
    chunk_size = 3,
    data = data.frame(id = integer()),
    apply_chunk = apply_chunk,
    parse_resp = function(resp) resp_body_json(resp, simplifyVector = TRUE)
  )

  responses <- req_perform_multi(req)
  expect_equal(responses, NULL)



  expect_equal(resps[[1]]$body, new_path(paths[[1]]))
  expect_equal(resps[[2]]$body, new_path(paths[[2]]))
})
