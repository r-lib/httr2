test_that("can send file", {
  skip_on_os("windows") # fails due to line ending difference

  path <- tempfile()
  writeLines("this is a test", path)

  resp <- request_test("/post") %>%
    req_body_file(path, type = "text/plain") %>%
    req_perform()

  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, "text/plain")
  expect_equal(json$data, "this is a test\n")
})

test_that("can send string", {
  resp <- request_httpbin("/post") %>%
    req_body_raw("test") %>%
    req_perform()

  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, NULL)
  expect_equal(json$data, "test")
})

test_that("can send named list as json/form/multipart", {
  data <- list(a = "1", b = "2")

  resp <- request_test("/post") %>%
    req_body_json(data) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_equal(json$json, data)

  resp <- request_test("/post") %>%
    req_body_form(data) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, "application/x-www-form-urlencoded")
  expect_equal(json$form, data)

  resp <- request_test("/post") %>%
    req_body_multipart(data) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_match(json$headers$`Content-Type`, "multipart/form-data; boundary=-")
  expect_equal(json$form, list(a = "1", b = "2"))
})

test_that("can modify body data", {
  req1 <- request_test("/GET") %>% req_body_form(list(a = 1))
  req2 <- req1 %>% req_body_form(list(b = 2))

  expect_equal(req1$body$data, list(a = 1))
  expect_equal(req2$body$data, list(a = 1, b = 2))
})

test_that("can upload file with multipart", {
  skip_on_os("windows") # fails due to line ending difference

  path <- tempfile()
  writeLines("this is a test", path)

  resp <- request_httpbin("/post") %>%
    req_body_multipart(list(file = curl::form_file(path))) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_match(json$files$file, "this is a test\n")
})
