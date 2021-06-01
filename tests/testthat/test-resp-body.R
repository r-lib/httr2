test_that("can retrieve parsed body", {
  resp <- req_test("/json") %>% req_fetch()
  expect_type(resp_body_json(resp), "list")

  resp <- req_test("/html") %>% req_fetch()
  expect_s3_class(resp_body_html(resp), "xml_document")

  resp <- req_test("/xml") %>% req_fetch()
  expect_s3_class(resp_body_xml(resp), "xml_document")
})

test_that("content types are checked", {
  expect_snapshot(error = TRUE, {
    req_test("/xml") %>% req_fetch() %>% resp_body_json()
    req_test("/json") %>% req_fetch() %>% resp_body_xml()
  })
})
