test_that("can extract headers and check for existence", {
  resp <- response(headers = "Content-Type: application/json")
  expect_type(resp_headers(resp), "list")
  expect_equal(resp_header(resp, "Content-Type"), "application/json")
  expect_equal(resp_header_exists(resp, "Content-Type"), TRUE)
})

test_that("headers are case-insenstive", {
  resp <- response(headers = "Content-Type: application/json")
  expect_equal(resp_header(resp, "content-type"), "application/json")
  expect_equal(resp_header_exists(resp, "content-type"), TRUE)
})

test_that("has tools for non-existent headers", {
  resp <- response()

  expect_equal(resp_header(resp, "non-existent"), NULL)
  expect_equal(resp_header(resp, "non-existent", "xyz"), "xyz")
  expect_equal(resp_header_exists(resp, "non-existent"), FALSE)
})

test_that("can extract content type/encoding", {
  resp <- response(headers = "Content-Type: text/html; charset=latin1")
  expect_equal(resp_content_type(resp), "text/html")
  expect_equal(resp_encoding(resp), "latin1")
})

test_that("can parse date header", {
  resp <- response(headers = "Date: Mon, 18 Jul 2016 16:06:00 GMT")
  expect_equal(resp_date(resp), local_time('2016-07-18 16:06:06'))
})

test_that("can parse both forms of retry-after header", {
  resp_abs <- response(headers = c(
    "Retry-After: Mon, 18 Jul 2016 16:06:10 GMT",
    "Date: Mon, 18 Jul 2016 16:06:00 GMT"
  ))
  expect_equal(resp_retry_after(resp_abs), 10)

  resp_rel <- response(headers = c(
    "Retry-After: 20"
  ))
  expect_equal(resp_retry_after(resp_rel), 20)

  resp_rel <- response()
  expect_equal(resp_retry_after(resp_rel), NA)
})

test_that("can extract specified link url", {
  resp <- response(headers = paste0(
    'Link: <https://example.com/1>; rel="next",',
    '<https://example.com/2>; rel="last"'
  ))
  expect_equal(resp_link_url(resp, "next"), "https://example.com/1")
  expect_equal(resp_link_url(resp, "last"), "https://example.com/2")

  # Falling back to NULL if not found
  expect_equal(resp_link_url(resp, "first"), NULL)
  expect_equal(resp_link_url(response(), "first"), NULL)
})

test_that("can extract from multiple link headers", {
  resp <- response(headers = c(
    'Link: <https://example.com/1>; rel="next"',
    'Link: <https://example.com/2>; rel="last"'
  ))
  expect_equal(resp_link_url(resp, "next"), "https://example.com/1")
  expect_equal(resp_link_url(resp, "last"), "https://example.com/2")
})
