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

  expect_equal(parse_media(""), list(type = NA_character_))
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

test_that("parse_in_half handles common cases", {
  parsed <- parse_in_half(c("a=b", "c=d", "e", "=f", "g=", "h=i=j"), "=")
  expect_equal(parsed$left, c("a", "c", "e", "", "g", "h"))
  expect_equal(parsed$right, c("b", "d", "", "f", "", "i=j"))
})

test_that("parse_in_half handles problematic inputs", {
  expect_equal(
    parse_in_half(character(0), "="),
    list(left = character(0), right = character(0))
  )
  expect_equal(
    parse_in_half("", "="),
    list(left = "", right = "")
  )
  expect_equal(
    parse_in_half(NA, "="),
    list(left = NA_character_, right = NA_character_)
  )
})

test_that("parse_in_half always returns two pieces", {
  expect_equal(parse_in_half("a", " "), list(left = "a", right = ""))
  expect_equal(parse_in_half("a b", " "), list(left = "a", right = "b"))
  expect_equal(parse_in_half("a b c", " "), list(left = "a", right = "b c"))
})



test_that("parse_name_equals_value handles empty values", {
  expect_equal(parse_name_equals_value("a"), list(a = ""))
})

