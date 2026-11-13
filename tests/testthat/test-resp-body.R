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

test_that("resp_body_multipart() works for varying parts", {
  parts <- c(
    "If you gave me a chance I would take it",
    # CRLFs are treated as part of the body
    "\r\nIt's a shot in the dark\r\nbut I'll make it\r\n",
    # multi-byte characters
    "Know with all of your ❤️  you can't shake me",
    # boundary-like strings that aren't delimiters
    "When I am with you (foo) there's no place (\r\n--foo) I'd rather (--foo--) be",
    ""
  )
  range <- function(start, part) {
    paste0(
      "Content-Range: bytes ",
      start,
      "-",
      start + nchar(part, "bytes") - 1,
      "/1000"
    )
  }

  body <- paste0(
    c(
      "yeah yeah yeah yeah yeah", # preamble
      "--foo",
      "",
      parts[1],
      "--foo",
      range(30, parts[2]),
      "",
      parts[2],
      "--foo",
      "Content-Type: text/plain",
      range(100, parts[3]),
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
      "No place I'd rather be--foo--" # epilogue
    ),
    collapse = "\r\n"
  )

  parsed <- resp_body_multipart(multipart_response(body))
  expect_length(parsed, length(parts))
  bodies <- lapply(parsed[1:4], resp_body_string)
  expect_equal(bodies, as.list(parts[1:4]))
  expect_equal(parsed[[5]]$body, raw())

  expect_named(resp_headers(parsed[[1]]), "Content-Type")
  expect_named(
    resp_headers(parsed[[2]]),
    c("Content-Range", "Content-Type"),
    ignore.order = TRUE
  )
  expect_named(
    resp_headers(parsed[[3]]),
    c("Content-Type", "Content-Range"),
    ignore.order = TRUE
  )
  expect_named(resp_headers(parsed[[4]]), "Content-Type")
  expect_named(resp_headers(parsed[[5]]), "Content-Type")
})

test_that("resp_body_multipart() supplies RFC 2046 default content type", {
  body <- "--foo\r\n\r\nhi\r\n--foo\r\ncontent-type: text/html\r\n\r\nhi\r\n--foo--"

  parsed <- resp_body_multipart(multipart_response(body))
  expect_equal(
    resp_header(parsed[[1]], "Content-Type"),
    "text/plain; charset=US-ASCII"
  )
  expect_equal(resp_header(parsed[[2]], "Content-Type"), "text/html")

  digest <- multipart_response(body, "multipart/digest; boundary=foo")
  parsed <- resp_body_multipart(digest)
  expect_equal(resp_header(parsed[[1]], "Content-Type"), "message/rfc822")
})

test_that("resp_body_multipart() handles body without preamble", {
  resp <- multipart_response("--foo\r\n\r\nhi\r\n--foo--")
  parsed <- resp_body_multipart(resp)
  expect_length(parsed, 1)
  expect_equal(resp_body_string(parsed[[1]]), "hi")
})

test_that("resp_body_multipart() handles binary parts and regex-like boundary", {
  body <- c(
    charToRaw("--a.b\r\n\r\n--axb\r\n"),
    as.raw(c(0, 1)),
    charToRaw("\r\n--a.b--")
  )
  resp <- multipart_response(body, 'multipart/mixed; boundary="a.b"')
  parsed <- resp_body_multipart(resp)
  expect_length(parsed, 1)
  expect_equal(
    resp_body_raw(parsed[[1]]),
    c(charToRaw("--axb\r\n"), as.raw(c(0, 1)))
  )
})

test_that("resp_body_multipart() allows transport padding after delimiters", {
  resp <- multipart_response(
    "--foo \t\r\n\r\nhi\r\n--foo  \r\n\r\nbye\r\n--foo--"
  )
  parsed <- resp_body_multipart(resp)
  expect_equal(lapply(parsed, resp_body_string), list("hi", "bye"))
})

test_that("resp_body_multipart() handles empty part without headers", {
  resp <- multipart_response("--foo\r\n\r\n--foo\r\n\r\nhi\r\n--foo--")
  parsed <- resp_body_multipart(resp)
  expect_length(parsed, 2)
  expect_equal(parsed[[1]]$body, raw())
  expect_equal(resp_body_string(parsed[[2]]), "hi")
})

test_that("multipart_boundary() follows RFC 2046", {
  boundary <- \(x) multipart_boundary(multipart_media(x))

  expect_equal(boundary("multipart/mixed; boundary=foo"), "foo")
  expect_equal(boundary("multipart/mixed; boundary=f"), "f")
  expect_equal(boundary("multipart/mixed;boundary=foo "), "foo")
  # quoted strings may contain spaces and tspecials
  expect_equal(
    boundary('multipart/mixed; boundary="a b?"; x=1'),
    "a b?"
  )
  # parameter names and types are case-insensitive
  expect_equal(boundary("Multipart/Mixed; Boundary=foo"), "foo")

  no_boundary <- "multipart/mixed"
  empty_boundary <- "multipart/mixed; boundary"
  bad_char <- 'multipart/mixed; boundary="a@b"'
  too_long <- paste0("multipart/mixed; boundary=", strrep("a", 71))
  expect_snapshot(error = TRUE, {
    boundary(no_boundary)
    boundary(empty_boundary)
    boundary(bad_char)
    boundary(too_long)
  })
})

test_that("resp_body_multipart() generates parsing errors", {
  wrong_type <- multipart_response("", "text/html")
  no_close <- multipart_response("kyoto to the bay\r\nstrolling so casually")
  no_open <- multipart_response(paste0(
    "kyoto to the bay\r\n--foo--\r\n",
    "strolling so casually\r\n--foo\r\n"
  ))
  no_header_line <- multipart_response(paste0(
    "\r\n--foo\r\nkyoto to the bay\r\n",
    "--foo\r\nstrolling so casually\r\n--foo--\r\n"
  ))
  no_header_end <- multipart_response(paste0(
    "\r\n--foo\r\nContent-Type: foo/bar\r\nkyoto to the bay\r\n",
    "--foo\r\n\r\nstrolling so casually\r\n--foo--\r\n"
  ))

  expect_snapshot(error = TRUE, {
    resp_body_multipart(wrong_type)
    resp_body_multipart(no_close)
    resp_body_multipart(no_open)
    resp_body_multipart(no_header_line)
    resp_body_multipart(no_header_end)
  })
})
