test_that("can parse media type", {
  # no params
  expect_equal(parse_media("text/plain"), list(type = "text/plain"))

  # single param
  expect_equal(
    parse_media("text/plain; charset=utf-8"),
    list(type = "text/plain", charset = "utf-8")
  )

  # single param with quotes
  expect_equal(
    parse_media("text/plain; charset=\"utf-8\""),
    list(type = "text/plain", charset = "utf-8")
  )

  # quoted param containing ;
  expect_equal(
    parse_media("text/plain; charset=\";\""),
    list(type = "text/plain", charset = ";")
  )
})

test_that("can parse authenticate header", {
  header <- paste0(
    'Bearer realm="example",',
    'error="invalid_token",','
    error_description="The access token expired"'
  )
  out <- parse_www_authenticate(header)
  expect_equal(out$scheme, "Bearer")
  expect_equal(out$realm, "example")
  expect_equal(out$error_description, "The access token expired")
})

test_that("can parse links", {
  header <- paste0(
    '<https://example.com/1>; rel="next",',
    '<https://example.com/2>; rel="last"'
  )
  expect_equal(
    parse_link(header),
    list(
      list(url = "https://example.com/1", rel = "next"),
      list(url = "https://example.com/2", rel = "last")
    )
  )
})


# Helpers -----------------------------------------------------------------

test_that("parse_in_half always returns two pieces", {
  expect_equal(parse_in_half("a", " "), c("a", ""))
  expect_equal(parse_in_half("a b", " "), c("a", "b"))
  expect_equal(parse_in_half("a b c", " "), c("a", "b c"))
})


