test_that("can add and remove headers", {
  req <- request("http://example.com")
  req <- req %>% req_headers(x = 1)
  expect_equal(req$headers, list(x = 1))
  req <- req %>% req_headers(x = NULL)
  expect_equal(req$headers, list())
})

test_that("can add header called req", {
  req <- request("http://example.com")
  req <- req %>% req_headers(req = 1)
  expect_equal(req$headers, list(req = 1))
})

test_that("can add repeated headers", {
  resp <- request_test("/get") %>%
    req_headers(a = c("a", "b")) %>%
    req_dry_run(quiet = TRUE)
  # https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.2
  expect_equal(resp$headers$a, c("a,b"))
})
