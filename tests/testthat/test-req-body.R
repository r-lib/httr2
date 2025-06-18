test_that("can't change body type", {
  req <- request("http://example.com") |> req_body_raw(raw(1))
  expect_snapshot(req |> req_body_json(list(x = 1)), error = TRUE)
})

test_that("useful values for empty body", {
  req <- request("http://example.com")
  expect_equal(req_body_type(req), "empty")
  expect_equal(req_body_info(req), "empty")
  expect_equal(req_get_body(req), NULL)
})

# req_body_raw() ---------------------------------------------------------------

test_that("can send string", {
  req <- request_test("/post") |> req_body_raw("test", type = "text/plain")
  expect_equal(req_body_type(req), "string")
  expect_equal(req_get_body(req), "test")
  expect_equal(req_body_info(req), "a string")

  resp <- req_perform(req)
  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, "text/plain")
  expect_equal(json$data, "test")
})

test_that("can send raw vector", {
  data <- charToRaw("abcdef")
  req <- request_test("/post") |> req_body_raw(data)
  expect_equal(req_body_type(req), "raw")
  expect_equal(req_get_body(req), data)
  expect_equal(req_body_info(req), "a 6 byte raw vector")

  resp <- req_perform(req)
  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, NULL)
  expect_equal(json$headers$`Content-Length`, "6")
})

test_that("can't send anything else", {
  req <- request_test()
  expect_snapshot(req_body_raw(req, 1), error = TRUE)
})

test_that("can override body content type", {
  req <- request_test("/post") |>
    req_body_raw('{"x":"y"}') |>
    req_headers("content-type" = "application/json")
  resp <- req_perform(req)
  headers <- resp_body_json(resp)$headers
  expect_equal(headers$`content-type`, "application/json")
  expect_equal(headers$`Content-Type`, NULL)
})

# req_body_file() --------------------------------------------------------------

test_that("can send file", {
  # curl requests in 64kb chunks so this will hopefully illustrate
  # any subtle problems
  path <- withr::local_tempfile()
  x <- strrep("x", 128 * 1024)
  writeChar(x, path, nchar(x))

  req <- request_test("/post") |> req_body_file(path, type = "text/plain")
  expect_equal(req_body_type(req), "file")
  expect_equal(rawToChar(req_get_body(req)), x)
  expect_equal(req_body_info(req), glue::glue("a path '{path}'"))

  resp <- req_perform(req)
  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, "text/plain")
  expect_equal(json$data, x)
})

test_that("can send file with redirect", {
  str <- paste(letters, collapse = "")
  path <- tempfile()
  writeChar(str, path)

  resp <- request_test("/redirect-to?url=/post&status_code=307") |>
    req_body_file(path, type = "text/plain") |>
    req_perform()

  expect_equal(resp_status(resp), 200)
  expect_equal(url_parse(resp$url)$path, "/post")
  expect_equal(resp_body_json(resp)$data, str)
})

test_that("errors on invalid input", {
  expect_snapshot(error = TRUE, {
    req_body_file(request_test(), 1)
    req_body_file(request_test(), "doesntexist")
    req_body_file(request_test(), ".")
  })
})
# req_body_json() --------------------------------------------------------------

test_that("can send any type of object as json", {
  req <- request_test("/post") |> req_body_json(mtcars)
  expect_equal(req$body$data, mtcars)

  data <- list(a = "1", b = "2")
  req <- request_test("/post") |> req_body_json(data)
  expect_equal(req_body_type(req), "json")
  expect_equal(req_body_info(req), "JSON data")
  expect_equal(req_get_body(req), '{"a":"1","b":"2"}')

  resp <- req_perform(req)
  json <- resp_body_json(resp)
  expect_equal(json$json, data)

  resp <- request_test("/post") |>
    req_body_json(letters) |>
    req_perform()
  json <- resp_body_json(resp)
  expect_equal(json$json, as.list(letters))
})

test_that("can use custom json type", {
  resp <- request_test("/post") |>
    req_body_json(mtcars, type = "application/ld+json") |>
    req_perform()

  expect_equal(
    resp_body_json(resp)$headers$`Content-Type`,
    "application/ld+json"
  )
})

test_that("non-json type errors", {
  expect_snapshot(
    req_body_json(request_test(), mtcars, type = "application/xml"),
    error = TRUE
  )
})

test_that("can modify json data", {
  req <- request_test() |>
    req_body_json(data = list(a = 1, b = 2, d = 4)) |>
    req_body_json_modify(a = 10, b = NULL, c = 3)
  expect_equal(req$body$data, list(a = 10, d = 4, c = 3))

  req <- request_test() |>
    req_body_json(data = list(a = list(b = list(c = 1, d = 2), e = 3))) |>
    req_body_json_modify(a = list(b = list(c = 101), e = 103))
  expect_equal(req$body$data, list(a = list(b = list(c = 101, d = 2), e = 103)))
})

test_that("can modify empty body", {
  req <- request_test() |>
    req_body_json_modify(a = 10, b = 20)
  expect_equal(req$body$data, list(a = 10, b = 20))
})

test_that("can't modify non-json data", {
  req <- request_test() |> req_body_raw("abc")
  expect_snapshot(req |> req_body_json_modify(a = 1), error = TRUE)
})

# req_body_form() --------------------------------------------------------------

test_that("can send named elements as form", {
  data <- list(a = "1", b = "2")

  req <- request_test("/post") |> req_body_form(!!!data)
  expect_equal(req_body_type(req), "form")
  expect_equal(req_body_info(req), "form data")
  expect_equal(req_get_body(req), "a=1&b=2")

  resp <- req_perform(req)
  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, "application/x-www-form-urlencoded")
  expect_equal(json$form, data)
})

test_that("can modify body data", {
  req1 <- request_test() |> req_body_form(a = 1)
  expect_equal(req1$body$data, list(a = I("1")))

  req2 <- req1 |> req_body_form(b = 2)
  expect_equal(req2$body$data, list(a = I("1"), b = I("2")))

  req3 <- req1 |> req_body_form(a = 3, a = 4)
  expect_equal(req3$body$data, list(a = I("3"), a = I("4")))
})

# req_body_multipart() ---------------------------------------------------------

test_that("can send named elements as multipart", {
  data <- list(a = "1", b = "2")

  req <- request_test("/post") |> req_body_multipart(!!!data)
  expect_equal(req_body_type(req), "multipart")
  expect_equal(req_body_info(req), "multipart data")
  expect_snapshot(
    cat(req_get_body(req)),
    transform = function(x) gsub("--------.*", "---{id}", x)
  )

  resp <- req_perform(req)
  json <- resp_body_json(resp)
  expect_match(json$headers$`Content-Type`, "multipart/form-data; boundary=-")
  expect_equal(json$form, list(a = "1", b = "2"))
})

test_that("can upload file with multipart", {
  skip_on_os("windows") # fails due to line ending difference

  path <- tempfile()
  writeLines("this is a test", path)

  resp <- request_test("/post") |>
    req_body_multipart(file = curl::form_file(path)) |>
    req_perform()
  json <- resp_body_json(resp)
  expect_equal(
    json$files$file$value,
    paste0(
      "data:application/octet-stream;base64,",
      openssl::base64_encode("this is a test\n")
    )
  )
})

test_that("no issues with partial name matching", {
  req <- request_test("/get") |>
    req_body_multipart(d = "some data")

  expect_named(req$body$data, "d")
})
