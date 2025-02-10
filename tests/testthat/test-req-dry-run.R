test_that("req_dry_run() returns useful data", {
  resp <- request("http://example.com") %>% req_dry_run(quiet = TRUE)
  expect_equal(resp$method, "GET")
  expect_equal(resp$path, "/")
  expect_match(resp$headers$`user-agent`, "libcurl")
})

test_that("body is shown", {
  req <- request("http://example.com") %>% req_verbose_test()

  # can display UTF-8 characters
  req_utf8 <- req_body_raw(req, "Cenário", type = "text/plain")
  expect_snapshot(req_dry_run(req_utf8))

  # json is not prettified
  req_json <- req_body_raw(req, '{"x":1,"y":true}', type = "application/json")
  expect_snapshot(req_dry_run(req_json))

  # doesn't show binary data
  req_binary <- req_body_raw(req, "Cenário")
  expect_snapshot(req_dry_run(req_binary))
})

test_that("authorization headers are redacted", {
  expect_snapshot({
    request("http://example.com") %>%
      req_headers(`Accept-Encoding` = "gzip") %>%
      req_auth_basic("user", "password") %>%
      req_user_agent("test") %>%
      req_dry_run()
  })
})

test_that("doen't add space to urls (#567)", {
  req <- request("https://example.com/test:1:2")
  expect_output(req_dry_run(req), "test:1:2")
})
