test_that("can paginate via next url", {
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
      headers = list(
        `content-type` = "application/json; charset=utf-8"
      )
    )
  }
  local_mock(next_url_mock)

  req1 <- request("https://pokeapi.co/api/v2/pokemon") %>%
    req_url_query(limit = 11) %>%
    req_paginate_next_url(
      next_url = \(resp) resp_body_json(resp)[["next"]]
    )

  resp <- req_perform(req1)
  req2 <- req1$policies$paginate$next_request(req1, resp)
  expect_equal(req2$url, link1)

  resp <- req_perform(req2)
  req3 <- req2$policies$paginate$next_request(req2, resp)
  expect_equal(req3$url, link2)
})

test_that("can paginate via offset", {
  req1 <- request("https://pokeapi.co/api/v2/pokemon") %>%
    req_url_query(limit = 11) %>%
    req_paginate_offset(
      offset = \(req, offset) req_url_query(req, offset = offset),
      page_size = 11
    )

  resp <- req_perform(req1)
  req2 <- req1$policies$paginate$next_request(req1, resp)
  expect_equal(req2$url, "https://pokeapi.co/api/v2/pokemon?limit=11&offset=11")
  # offset stays the same when applied twice
  expect_equal(req2$url, "https://pokeapi.co/api/v2/pokemon?limit=11&offset=11")

  resp <- req_perform(req2)
  req3 <- req2$policies$paginate$next_request(req2, resp)
  expect_equal(req3$url, "https://pokeapi.co/api/v2/pokemon?limit=11&offset=22")
})
