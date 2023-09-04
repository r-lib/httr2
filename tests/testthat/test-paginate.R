test_that("req_paginate() checks inputs", {
  req <- request("http://example.com/")
  next_request <- function(req, resp, body) req

  expect_snapshot(error = TRUE, {
    req_paginate("a", next_request)
    req_paginate(req, "a")
    req_paginate(req, function(req) req)
    req_paginate(req, next_request, n_pages = "a")
    req_paginate(req, next_request, n_pages = function(x) x)
  })
})

test_that("paginate_next_request() produces the request to the next page", {
  resp <- response()
  f_next_request <- function(req, resp, body) {
    req_url_path(req, "/2")
  }
  f_n_pages <- function(resp, body) 3

  req <- req_paginate(
    request("http://example.com/"),
    next_request = f_next_request,
    n_pages = f_n_pages
  )

  expect_snapshot(error = TRUE, {
    paginate_next_request("a", req)
    paginate_next_request(resp, "a")
    paginate_next_request(resp, request("http://example.com/"))
  })

  out <- paginate_next_request(resp, req)
  expect_equal(out$url, "http://example.com/2")
  expect_equal(req$policies$paginate$n_pages(resp), 3)
})

test_that("req_paginate_next_url() checks inputs", {
  expect_snapshot(error = TRUE, {
    req_paginate_next_url(request("http://example.com/"), "a")
    req_paginate_next_url(request("http://example.com/"), function(req, body) req)
  })
})

test_that("req_paginate_next_url() can paginate", {
  link1 <- "https://pokeapi.co/api/v2/pokemon?offset=11&limit=11"
  link2 <- "https://pokeapi.co/api/v2/pokemon?offset=22&limit=11"

  next_url_mock <- function(req) {
    if (req$url == "https://pokeapi.co/api/v2/pokemon?limit=11") {
      link <- link1
    } else {
      link <- link2
    }

    body <- glue::glue(
      '{"count":1281,"next":"<link>","previous":null,"results":[{"name":"bulbasaur","url":"https://pokeapi.co/api/v2/pokemon/1/"}]}',
      .open = "<",
      .close = ">"
    )

    response(
      url = "https://pokeapi.co/api/v2/pokemon?limit=11",
      status_code = 200L,
      body = charToRaw(body),
      headers = list(`content-type` = "application/json; charset=utf-8")
    )
  }
  local_mock(next_url_mock)

  req1 <- request("https://pokeapi.co/api/v2/pokemon") %>%
    req_url_query(limit = 11) %>%
    req_paginate_next_url(
      next_url = function(resp, body) resp_body_json(resp)[["next"]]
    )

  resp <- req_perform(req1)
  req2 <- paginate_next_request(resp, req1)
  expect_equal(req2$url, link1)

  resp <- req_perform(req2)
  req3 <- paginate_next_request(resp, req2)
  expect_equal(req3$url, link2)
})

test_that("req_paginate_offset() checks inputs", {
  req <- request("http://example.com/")

  expect_snapshot(error = TRUE, {
    req_paginate_offset(req, "a")
    req_paginate_offset(req, function(req) req)
    req_paginate_offset(req, function(req, offset) req, page_size = "a")
  })
})

test_that("req_paginate_offset() can paginate", {
  req1 <- request("https://pokeapi.co/api/v2/pokemon") %>%
    req_url_query(limit = 11) %>%
    req_paginate_offset(
      offset = function(req, offset) req_url_query(req, offset = offset),
      page_size = 11
    )

  resp <- req_perform(req1)
  req2 <- paginate_next_request(resp, req1)
  expect_equal(req2$url, "https://pokeapi.co/api/v2/pokemon?limit=11&offset=11")
  # offset stays the same when applied twice
  expect_equal(req2$url, "https://pokeapi.co/api/v2/pokemon?limit=11&offset=11")

  resp <- req_perform(req2)
  req3 <- paginate_next_request(resp, req2)
  expect_equal(req3$url, "https://pokeapi.co/api/v2/pokemon?limit=11&offset=22")
})

test_that("req_paginate_token() checks inputs", {
  req <- request("http://example.com/")

  expect_snapshot(error = TRUE, {
    req_paginate_token(req, "a")
    req_paginate_token(req, function(req) req)
    req_paginate_token(req, function(req, token) req, next_token = "a")
    req_paginate_token(req, function(req, token) req, next_token = function(req) req)
  })
})

test_that("req_paginate_token() can paginate", {
  u <- jsonlite::unbox
  next_url_mock <- function(req) {
    cur_token <- req$body$data$my_token %||% 1L
    body <- jsonlite::toJSON(list(x = 1, my_next_token = u(cur_token + 1L)))

    response(
      url = req$url,
      body = charToRaw(body),
      headers = list(`content-type` = "application/json; charset=utf-8")
    )
  }
  local_mock(next_url_mock)

  req1 <- request("http://example.com") %>%
    req_paginate_token(
      set_token = function(req, token) {
        req_body_json(req, list(my_token = u(token)))
      },
      next_token = function(resp, body) {
        resp_body_json(resp)$my_next_token
      }
    )

  resp <- req_perform(req1)
  req2 <- paginate_next_request(resp, req1)
  expect_equal(req2$body$data$my_token, u(2L))

  resp <- req_perform(req2)
  req3 <- paginate_next_request(resp, req2)
  expect_equal(req3$body$data$my_token, u(3L))
})

test_that("paginate_req_perform() checks inputs", {
  req <- request("http://example.com") %>%
    req_paginate_token(
      set_token = function(req, token) {
        req_body_json(req, list(my_token = u(token)))
      },
      next_token = function(resp, body) {
        resp_body_json(resp)$my_next_token
      }
    )

  expect_snapshot(error = TRUE, {
    paginate_req_perform("a")
    paginate_req_perform(request("http://example.com"))
    paginate_req_perform(req, max_pages = 0)
    paginate_req_perform(req, progress = "a")
  })
})

test_that("paginate_req_perform() iterates through pages", {
  u <- jsonlite::unbox
  next_url_mock <- function(req) {
    cur_token <- req$body$data$my_token %||% 1L
    if (cur_token == 4) {
      body <- jsonlite::toJSON(list(x = 1))
    } else {
      body <- jsonlite::toJSON(list(x = 1, my_next_token = u(cur_token + 1L)))
    }

    response(
      url = req$url,
      body = charToRaw(body),
      headers = list(
        `content-type` = "application/json; charset=utf-8",
        date = "2023-09-01"
      )
    )
  }
  local_mock(next_url_mock)

  req <- request("http://example.com") %>%
    req_paginate_token(
      set_token = function(req, token) {
        req_body_json(req, list(my_token = u(token)))
      },
      next_token = function(resp, body) {
        resp_body_json(resp)$my_next_token
      }
    )

  responses_2 <- paginate_req_perform(req, max_pages = 2)
  expect_length(responses_2, 2)
  expect_equal(resp_body_json(responses_2[[1]]), list(x = list(1), my_next_token = 2))
  expect_equal(resp_body_json(responses_2[[2]]), list(x = list(1), my_next_token = 3))

  responses_5 <- paginate_req_perform(req, max_pages = 5)
  expect_length(responses_5, 4)

  responses_inf <- paginate_req_perform(req, max_pages = Inf)
  expect_equal(responses_inf, responses_5)
})
