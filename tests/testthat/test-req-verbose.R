
test_that("can request verbose record of request", {
  req <- request_test("/post") %>%
    req_body_raw("This is some text") %>%
    req_verbose_test()

  # Snapshot test of response
  verbose_resp <- req %>% req_verbose(header_resp = TRUE, body_resp = TRUE, header_req = FALSE)
  expect_snapshot(. <- req_perform(verbose_resp), transform = transform_verbose_response)

  # Snapshot test of request
  verbose_req <- req %>% req_verbose(header_req = TRUE, body_req = TRUE, header_resp = FALSE)
  expect_snapshot(. <- req_perform(verbose_req), transform = transform_verbose_response)

  # Lightweight test for everything else
  verbose_info <- req %>% req_verbose(info = TRUE, header_req = FALSE, header_resp = FALSE)
  expect_output(. <- req_perform(verbose_info))
})

test_that("can display compressed bodies", {
  req <- request(example_url()) %>%
    req_url_path("gzip") %>%
      req_verbose_test() %>%
    req_verbose(header_req = FALSE, header_resp = TRUE, body_resp = TRUE)

  expect_snapshot(. <- req_perform(req), transform = transform_verbose_response)
})

test_that("verbose_enum checks range", {
  expect_snapshot({
    verbose_enum(7)
  })
})
