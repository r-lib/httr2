test_that("can add and remove headers", {
  req <- request("http://example.com")
  req <- req %>% req_headers(x = 1)
  expect_equal(req$headers, structure(list(x = 1), redact = character()))
  req <- req %>% req_headers(x = NULL)
  expect_equal(req$headers, structure(list(), redact = character()))
})

test_that("can add header called req", {
  req <- request("http://example.com")
  req <- req %>% req_headers(req = 1)
  expect_equal(req$headers, structure(list(req = 1), redact = character()))
})

test_that("can add repeated headers", {
  resp <- request_test() %>%
    req_headers(a = c("a", "b")) %>%
    req_dry_run(quiet = TRUE)
  # https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.2
  expect_equal(resp$headers$a, c("a,b"))
})

test_that("can control which headers to redact", {
  expect_redact <- function(req, expected) {
    expect_equal(attr(req$headers, "redact"), expected)
  }

  req <- request("http://example.com")
  expect_redact(req_headers(req, a = 1L, b = 2L), character())
  expect_redact(req_headers(req, a = 1L, b = 2L, .redact = c("a", "b")), c("a", "b"))
  expect_redact(req_headers(req, a = 1L, b = 2L, .redact = "a"), "a")

  expect_snapshot(error = TRUE, {
    req_headers(req, a = 1L, b = 2L, .redact = 1L)
  })
})
