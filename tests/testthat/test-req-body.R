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

test_that("can send any type of object as json", {
  req <- request_test("/post") %>% req_body_json(mtcars)
  expect_equal(req$body$data, mtcars)

  data <- list(a = "1", b = "2")
  resp <- request_test("/post") %>%
    req_body_json(data) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_equal(json$json, data)

  resp <- request_test("/post") %>%
    req_body_json(letters) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_equal(json$json, as.list(letters))
})

test_that("can use custom json type", {
  req <- request_test("/post") %>% req_body_json(mtcars)
  expect_equal(req_body_apply(req)$headers$`Content-Type`, "application/json")

  content_type <- "application/ld+json"
  req <- req %>% req_headers(`Content-Type` = "application/ld+json")
  expect_equal(req_body_apply(req)$headers$`Content-Type`, content_type)

  expect_snapshot({
    (expect_error(req %>% req_headers(`Content-Type` = "application/ld+json2") %>% req_body_apply()))
  })
})

test_that("can send named elements as form/multipart", {
  data <- list(a = "1", b = "2")

  resp <- request_test("/post") %>%
    req_body_form(!!!data) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_equal(json$headers$`Content-Type`, "application/x-www-form-urlencoded")
  expect_equal(json$form, data)

  resp <- request_test("/post") %>%
    req_body_multipart(!!!data) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_match(json$headers$`Content-Type`, "multipart/form-data; boundary=-")
  expect_equal(json$form, list(a = "1", b = "2"))
})

test_that("can modify body data", {
  req1 <- request_test() %>% req_body_form(a = 1)
  expect_equal(req1$body$data, list(a = 1))

  req2 <- req1 %>% req_body_form(b = 2)
  expect_equal(req2$body$data, list(a = 1, b = 2))

  req3 <- req1 %>% req_body_form(a = 3, a = 4)
  expect_equal(req3$body$data, list(a = 3, a = 4))
})

test_that("req_body_form() and req_body_multipart() accept list() with warning", {
  req <- request_test()
  expect_snapshot({
    req1 <- req %>% req_body_form(list(x = "x"))
    req2 <- req %>% req_body_multipart(list(x = "x"))
  })
  expect_equal(req1$body$data, list(x = "x"))
  expect_equal(req2$body$data, list(x = "x"))
})

test_that("can upload file with multipart", {
  skip_on_os("windows") # fails due to line ending difference

  path <- tempfile()
  writeLines("this is a test", path)

  resp <- request_httpbin("/post") %>%
    req_body_multipart(file = curl::form_file(path)) %>%
    req_perform()
  json <- resp_body_json(resp)
  expect_match(json$files$file, "this is a test\n")
})

test_that("can override body content type", {
  req <- request_test("/post") %>%
    req_body_raw('{"x":"y"}') %>%
    req_headers("content-type" = "application/json")
  resp <- req_perform(req)
  headers <- resp_body_json(resp)$headers
  expect_equal(headers$`Content-Type`, "application/json")
  expect_equal(headers$`content-type`, NULL)
})
