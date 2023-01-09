test_that("read body from disk/memory", {
  resp1 <- request_test("base64/:value", value = "SGk=") %>% req_perform()
  expect_equal(resp_body_raw(resp1), charToRaw("Hi"))
  expect_equal(resp_body_string(resp1), "Hi")

  resp2 <- request_test("base64/:value", value = "SGk=") %>% req_perform(tempfile())
  expect_equal(resp_body_string(resp2), "Hi")
})

test_that("empty body generates error", {
  expect_snapshot({
    request_test("HEAD /get") %>% req_perform() %>% resp_body_raw()
  }, error = TRUE)
})


test_that("can retrieve parsed body", {
  resp <- request_test("/json") %>% req_perform()
  expect_type(resp_body_json(resp), "list")

  resp <- request_test("/html") %>% req_perform()
  expect_s3_class(resp_body_html(resp), "xml_document")

  resp <- request_test("/xml") %>% req_perform()
  expect_s3_class(resp_body_xml(resp), "xml_document")
})

test_that("content types are checked", {
  expect_snapshot(error = TRUE, {
    request_test("/xml") %>% req_perform() %>% resp_body_json()
    request_test("/json") %>% req_perform() %>% resp_body_xml()
  })
})

test_that("check_content_type() can consult suffixes", {
  resp <- response(headers = "Content-type: application/vnd.github-issue.text+json")
  expect_null(check_resp_content_type(resp, "application/json"))
})
