# iterate_with_offset -----------------------------------------------------

test_that("iterate_with_offset checks inputs", {
  expect_snapshot(error = TRUE, {
    iterate_with_offset(1)
    iterate_with_offset("x", "x")
    iterate_with_offset("x", offset = 0)
    iterate_with_offset("x", offset = "x")
    iterate_with_offset("x", resp_complete = function(x, y) x + y)
  })
})

test_that("increments param_name by offset", {
  req_1 <- request_test()
  iterator <- iterate_with_offset("page")

  req_2 <- iterator(response(), req_1)
  expect_equal(url_parse(req_2$url)$query, list(page = "2"))

  req_3 <- iterator(response(), req_2)
  expect_equal(url_parse(req_3$url)$query, list(page = "3"))
})

test_that("can compute total pages", {
  req_1 <- request_test()
  iterator <- iterate_with_offset("page", resp_pages = function(resp) {
    resp_body_json(resp)$n
  })

  expect_no_condition(
    req_2 <- iterator(response_json(), req_1),
    class = "httr2_total_pages"
  )

  expect_condition(
    req_3 <- iterator(response_json(body = list(n = 100)), req_2),
    class = "httr2_total_pages"
  )

  # Only called once
  expect_no_condition(
    req_4 <- iterator(response_json(body = list(n = 200)), req_3),
    class = "httr2_total_pages"
  )
})

test_that("can terminate early", {
  req_1 <- request_test()
  iterator <- iterate_with_offset("page", resp_complete = function(resp) {
    resp_body_json(resp)$done
  })

  req_2 <- iterator(response_json(body = list(done = FALSE)), req_1)
  expect_equal(url_parse(req_2$url)$query, list(page = "2"))

  req_3 <- iterator(response_json(body = list(done = TRUE)), req_2)
  expect_null(req_3)
})

# iterate_with_cursor -----------------------------------------------------

test_that("iterate_with_cursor", {
  expect_snapshot(error = TRUE, {
    iterate_with_cursor(1)
    iterate_with_cursor("x", function(x, y) x + y)
  })
})

test_that("updates param_name with new value", {
  req_1 <- request_test()
  iterator <- iterate_with_cursor("next_cursor", function(resp) {
    resp_body_json(resp)$cursor
  })

  req_2 <- iterator(response_json(body = list(cursor = 123)), req_1)
  expect_equal(url_parse(req_2$url)$query, list(next_cursor = "123"))

  req_3 <- iterator(response_json(body = list()), req_2)
  expect_null(req_3)
})

# iterate_with_link_url -----------------------------------------------------

test_that("iterate_with_link_url checks its inputs", {
  expect_snapshot(error = TRUE, {
    iterate_with_link_url(rel = 1)
  })
})

test_that("updates the full url", {
  req_1 <- request_test()
  iterator <- iterate_with_link_url()

  resp <- response(headers = 'Link: <https://example.com/page/2>; rel="next"')
  req_2 <- iterator(resp, req_1)
  expect_equal(req_2$url, "https://example.com/page/2")

  req_3 <- iterator(response(), req_2)
  expect_null(req_3)
})
