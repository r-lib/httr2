test_that("read body from disk/memory", {
  resp1 <- request_test("base64/:value", value = "SGk=") |> req_perform()
  expect_true(resp_has_body(resp1))
  expect_equal(resp_body_raw(resp1), charToRaw("Hi"))
  expect_equal(resp_body_string(resp1), "Hi")

  resp2 <- request_test("base64/:value", value = "SGk=") |>
    req_perform(tempfile())
  expect_true(resp_has_body(resp2))
  expect_equal(resp_body_string(resp2), "Hi")
})

test_that("empty body generates error", {
  resp1 <- request_test("HEAD /get") |> req_perform()
  expect_false(resp_has_body(resp1))
  expect_snapshot(resp_body_raw(resp1), error = TRUE)

  resp2 <- request_test("HEAD /get") |> req_perform(tempfile())
  expect_false(resp_has_body(resp2))
  expect_snapshot(resp_body_raw(resp2), error = TRUE)
})

test_that("can retrieve parsed body", {
  resp <- request_test("/json") |> req_perform()
  expect_type(resp_body_json(resp), "list")

  resp <- request_test("/html") |> req_perform()
  expect_s3_class(resp_body_html(resp), "xml_document")

  resp <- request_test("/xml") |> req_perform()
  expect_s3_class(resp_body_xml(resp), "xml_document")
})

test_that("can retrieve parsed body when saved to a file", {
  path <- withr::local_tempfile()
  resp <- request_test("/json") |> req_perform(path)
  expect_type(resp_body_json(resp), "list")

  resp <- request_test("/html") |> req_perform(path)
  expect_s3_class(resp_body_html(resp), "xml_document")

  resp <- request_test("/xml") |> req_perform(path)
  expect_s3_class(resp_body_xml(resp), "xml_document")
})

test_that("resp_body_json stores parsed result", {
  resp <- request_test("/json") |> req_perform()
  json1 <- resp_body_json(resp)
  # check it's saved
  expect_length(resp$cache, 1)

  # check it's not recomputed
  json2 <- resp_body_json(resp)
  expect_true(is_reference(json2, json1))

  # check the arguments matter
  json3 <- resp_body_json(resp, simplifyVector = TRUE)
  expect_false(is_reference(json3, json1))
  expect_length(resp$cache, 2)
})

test_that("resp_body_xml stores parsed result", {
  resp <- request_test("/xml") |> req_perform()
  xml1 <- resp_body_xml(resp)
  # check it's saved
  expect_length(resp$cache, 1)

  # check it's not recomputed
  xml2 <- resp_body_xml(resp)
  expect_true(is_reference(xml2, xml1))
})

test_that("check argument types before caching", {
  expect_snapshot(error = TRUE, {
    resp_body_json(1)
    resp_body_xml(1)
  })
})

test_that("content types are checked", {
  expect_snapshot(error = TRUE, {
    request_test("/xml") |> req_perform() |> resp_body_json()
    request_test("/json") |> req_perform() |> resp_body_xml()
  })

  resp <- request_test("/json") |> req_perform()
  resp$headers$`Content-Type` <- "application/xml"
  expect_error(resp_body_json(resp))
  expect_no_error(resp_body_json(resp, check_type = FALSE))
})

# library(httr2); library(testthat)

test_that("resp_body_multipart works for varying parts", {
  parts <- c(
    "If you gave me a chance I would take it",
    "\r\nIt's a shot in the dark\r\nbut I'll make it\r\n", # CRLFs are treated as part of the body
    "Know with all of your ❤️  you can't shake me", # correct behavior with multi-byte chars
    "When I am with you (foo) there's no place (\r\n--foo) I'd rather (--foo--) be", # ignore pathological boundary-like strings
    "" # empty body
  )

  full_body <- charToRaw(paste0(
    c(
      "yeah yeah yeah yeah yeah", # preamble
      "--foo", # No headers at all.
      "",
      parts[1],
      "--foo",
      paste0(
        "Content-Range: bytes 30-",
        30 + nchar(parts[2], "bytes") - 1,
        "/1000"
      ),
      "",
      parts[2],
      "--foo", # Multiple headers
      "Content-Type: text/plain",
      paste0(
        "Content-Range: bytes 100-",
        100 + nchar(parts[3], "bytes") - 1,
        "/1000"
      ),
      "",
      parts[3],
      "--foo",
      "Content-Type: text/plain",
      "",
      parts[4],
      "--foo",
      "",
      parts[5],
      "--foo--",
      "No place I'd rather be--foo--" # ignore everything after the first terminating boundary.
    ),
    collapse = "\r\n"
  ))

  mock_resp <- new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = "multipart/byteranges; boundary=foo"),
    body = full_body
  )

  parsed <- resp_body_multipart(mock_resp)
  expect_identical(length(parsed), length(parts))
  for (i in seq_along(parts)) {
    if (parts[i] != "") {
      expect_identical(resp_body_raw(parsed[[i]]), charToRaw(parts[i]))
    } else {
      expect_false(resp_has_body(parsed[[i]]))
    }
  }

  expect_identical(length(resp_headers(parsed[[1]])), 0L)
  expect_identical(names(resp_headers(parsed[[2]])), "Content-Range")
  expect_identical(
    sort(names(resp_headers(parsed[[3]]))),
    c("Content-Range", "Content-Type")
  )
  expect_identical(names(resp_headers(parsed[[4]])), "Content-Type")
  expect_identical(length(resp_headers(parsed[[5]])), 0L)
})

test_that("multipart boundary extraction works with spaces", {
  # Spaces in the boundary string are allowed.
  boundary <- httr2:::extract_multipart_boundary(
    "multipart/digest; boundary=-- I am the boundary --; other=stuff"
  )
  expect_identical(boundary, "-- I am the boundary --")

  # Boundary cannot terminate with a space.
  boundary <- httr2:::extract_multipart_boundary(
    "multipart/digest; boundary=-- I am the boundary -- "
  )
  expect_identical(boundary, "-- I am the boundary --")

  # Handles varying number of spaces between the ';' and 'boundary='.
  boundary <- httr2:::extract_multipart_boundary(
    "multipart/digest;boundary=-- I am the boundary --"
  )
  expect_identical(boundary, "-- I am the boundary --")
  boundary <- httr2:::extract_multipart_boundary(
    "multipart/digest;    boundary=-- I am the boundary --"
  )
  expect_identical(boundary, "-- I am the boundary --")

  expect_error(
    httr2:::extract_multipart_boundary("multipart/digest; boundary"),
    "Failed to extract multipart boundary"
  )
})

test_that("resp_body_multipart generates parsing errors", {
  mock_resp <- new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = "text/html"),
    raw()
  )
  expect_error(resp_body_multipart(mock_resp), "Unexpected content type")

  payload <- charToRaw("kyoto to the bay\r\nstrolling so casually")
  mock_resp <- new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = "multipart/byteranges; boundary=foo"),
    body = payload
  )
  expect_error(resp_body_multipart(mock_resp), "No closing delimiter")

  # No non-closing delimiter before the closing delimiter.
  payload <- charToRaw(
    "kyoto to the bay\r\n--foo--\r\nstrolling so casually\r\n--foo\r\n"
  )
  mock_resp <- new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = "multipart/byteranges; boundary=foo"),
    body = payload
  )
  expect_error(resp_body_multipart(mock_resp), "No non-closing delimiter")

  payload <- charToRaw(
    "kyoto to the bay\r\n--foo\r\n--foo\r\nstrolling so casually\r\n--foo--\r\n"
  )
  mock_resp <- new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = "multipart/byteranges; boundary=foo"),
    body = payload
  )
  expect_error(resp_body_multipart(mock_resp), "too short")

  # No empty line with no headers.
  payload <- charToRaw(
    "\r\n--foo\r\nkyoto to the bay\r\n--foo\r\nstrolling so casually\r\n--foo--\r\n"
  )
  mock_resp <- new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = "multipart/byteranges; boundary=foo"),
    body = payload
  )
  expect_error(
    resp_body_multipart(mock_resp),
    "Failed to parse per-part headers"
  )

  # No empty line after headers.
  payload <- charToRaw(
    "\r\n--foo\r\nContent-Type: foo/bar\r\nkyoto to the bay\r\n--foo\r\n\r\nstrolling so casually\r\n--foo--\r\n"
  )
  mock_resp <- new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = "multipart/byteranges; boundary=foo"),
    body = payload
  )
  expect_error(
    resp_body_multipart(mock_resp),
    "Failed to parse per-part headers"
  )
})
