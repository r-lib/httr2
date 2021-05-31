test_that("can send empty body", {
  resp <- req_test("/post") %>%
    req_body_none() %>%
    req_fetch()

  expect_equal(resp_status(resp), 200)
  expect_equal(resp$body, raw())
})

test_that("can send file", {
  skip_on_os("windows") # fails due to line ending difference

  path <- tempfile()
  writeLines("this is a test", path)

  resp <- req_test("/post") %>%
    req_body_file(path, type = "text/plain") %>%
    req_fetch()

  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, "text/plain")
  expect_equal(json$data, "this is a test\n")
})

test_that("can send string", {
  resp <- req_httpbin("/post") %>%
    req_body_raw("test") %>%
    req_fetch()

  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, NULL)
  expect_equal(json$data, "test")
})

test_that("can send named list as json/form/multipart", {
  data <- list(a = "1", b = "2")

  resp <- req_test("/post") %>%
    req_body_json(data) %>%
    req_fetch()
  json <- resp_body_json(resp)
  expect_equal(json$json, data)

  resp <- req_test("/post") %>%
    req_body_form(data) %>%
    req_fetch()
  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, "application/x-www-form-urlencoded")
  expect_equal(json$form, data)

  resp <- req_test("/post") %>%
    req_body_multipart(data) %>%
    req_fetch()
  json <- resp_body_json(resp)
  expect_match(json$headers$`Content-Type`, "multipart/form-data; boundary=-")
  expect_equal(json$form, list(a = "1", b = "2"))
})

test_that("can upload file with multipart", {
  skip_on_os("windows") # fails due to line ending difference

  path <- tempfile()
  writeLines("this is a test", path)

  resp <- req_httpbin("/post") %>%
    req_body_multipart(list(file = curl::form_file(path))) %>%
    req_fetch()
  json <- resp_body_json(resp)
  expect_match(json$files$file, "this is a test\n")
})
