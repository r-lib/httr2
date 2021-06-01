test_that("can extract headers and check for existence", {
  resp <- response(headers = "Content-Type: application/json")
  expect_type(resp_headers(resp), "list")
  expect_equal(resp_header(resp, "Content-Type"), "application/json")
  expect_equal(resp_header_exists(resp, "Content-Type"), TRUE)

  expect_equal(resp_header(resp, "non-existent"), NULL)
  expect_equal(resp_header_exists(resp, "non-existent"), FALSE)

})
test_that("can extract content type/encoding", {
  resp <- response(headers = "Content-Type: text/html; charset=latin1")
  expect_equal(resp_content_type(resp), "text/html")
  expect_equal(resp_encoding(resp), "latin1")
})

test_that("can parse date header", {
  resp <- response(headers = "Date: Mon, 18 Jul 2016 16:06:00 GMT")
  expect_equal(resp_date(resp), as.POSIXct('2016-07-18 16:06:06', tz = "GMT"))
})
