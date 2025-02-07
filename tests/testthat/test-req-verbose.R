
test_that("can request verbose record of request", {
  req <- request_test("/post") %>% req_body_raw("This is some text")

  # Snapshot test of what can be made reproducible
  req1 <- req %>%
    req_headers_reset() %>%
    req_verbose(header_resp = TRUE, body_req = TRUE, body_resp = TRUE)
  expect_snapshot(. <- req_perform(req1), transform = transform_resp_headers)

  # Lightweight test for everything else
  req2 <- req %>% req_verbose(info = TRUE)
  expect_output(req_perform(req2))
})

test_that("can display compressed bodies", {
  req <- request(example_url()) |>
    req_url_path("gzip") |>
    req_headers_reset() |>
    req_verbose(header_req = FALSE, header_resp = TRUE, body_resp = TRUE)

  expect_snapshot(. <- req_perform(req), transform = transform_resp_headers)
})
