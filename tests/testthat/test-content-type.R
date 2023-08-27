test_that("can check type of response", {
  resp1 <- response(headers = c("Content-type: application/json"))
  resp2 <- response(headers = c("Content-type: xxxxx"))

  expect_no_error(
    check_resp_content_type(resp1, "application/json")
  )
  expect_no_error(
    check_resp_content_type(resp1, "application/xml", check_type = FALSE)
  )
  expect_snapshot(error = TRUE, {
    check_resp_content_type(resp1, "application/xml")
    check_resp_content_type(resp2, "application/xml")
  })
})

test_that("useful error even if no content type", {
  resp <- response()
  expect_snapshot(check_resp_content_type(resp, "application/xml"), error = TRUE)
})

test_that("can parse content type", {
  expect_equal(
    parse_content_type("application/json"),
    list(type = "application", subtype = "json", suffix = "")
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

test_that("invalid type returns empty strings", {
  expect_equal(
    parse_content_type(""),
    list(type = "", subtype = "", suffix = "")
  )
})

test_that("check_content_type() can consult suffixes", {
  expect_no_error(check_content_type("application/json", "application/json"))
  expect_snapshot(check_content_type("application/json", "application/xml"), error = TRUE)

  # works with suffixes
  expect_no_error(check_content_type("application/test+json", "application/json", "json"))
  expect_snapshot(
    check_content_type("application/test+json", "application/xml", "xml"),
    error = TRUE
  )

  # can use multiple valid types
  expect_no_error(
    check_content_type("application/test+json", c("text/html", "application/json"), "json")
  )
  expect_snapshot(
    check_content_type("application/xml", c("text/html", "application/json")),
    error = TRUE
  )
})
