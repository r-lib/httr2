test_that("can parse content type", {
  expect_equal(
    parse_content_type("application/json"),
    list(type = "application", subtype = "json", suffix = NULL)
  )

  # can parse suffix
  expect_equal(
    parse_content_type("text/html+xml"),
    list(type = "text", subtype = "html", suffix = "xml")
  )

  # parameters don't matter
  expect_equal(
    parse_content_type("text/html+xml;charset=UTF-8"),
    list(type = "text", subtype = "html", suffix = "xml")
  )
})

test_that("", {
  expect_snapshot({
    (expect_error(check_content_type("application/ld+json2", "application/json")))
    (expect_error(check_content_type("app/ld+json", "application/json")))
  })
})

test_that("check_content_type() can consult suffixes", {
  expect_no_error(check_content_type("application/json", "application/json"))
  expect_snapshot({
    (expect_error(check_content_type("application/json", "application/xml")))
  })
  # works with suffixes
  expect_no_error(check_content_type("application/test+json", "application/json"))
  expect_snapshot({
    (expect_error(check_content_type("application/test+json", "application/xml")))
  })
  # can use multiple valid types
  expect_no_error(check_content_type("application/test+json", c("text/html", "application/json")))
  expect_snapshot({
    (expect_error(check_content_type("application/xml", c("text/html", "application/json"))))
  })

  # `valid_types` can have a suffix
  expect_no_error(check_content_type("application/xhtml+xml", "application/xhtml+xml"))
  expect_snapshot({
    (expect_error(check_content_type("application/xml", "application/xhtml+xml")))
  })
})
