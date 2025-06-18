test_that("req_dry_run() returns useful data", {
  resp <- request("http://example.com") %>%
    req_dry_run(quiet = TRUE, testing_headers = FALSE)
  expect_equal(resp$method, "GET")
  expect_equal(resp$path, "/")
  expect_match(resp$headers$`user-agent`, "libcurl")
})

test_that("body is shown", {
  req <- request("http://example.com")

  # can display UTF-8 characters
  req_utf8 <- req_body_raw(req, "Cenário", type = "text/plain")
  expect_snapshot(req_dry_run(req_utf8))

  # json is prettified by default
  req_json <- req_body_raw(req, '{"x":1,"y":true}', type = "application/json")
  expect_snapshot(req_dry_run(req_json))
  expect_snapshot(req_dry_run(req_json, pretty_json = FALSE))

  # doesn't show binary data
  req_binary <- req_body_raw(req, charToRaw("Cenário"))
  expect_snapshot(req_dry_run(req_binary))
})

test_that("authorization headers are redacted", {
  req <- request("http://example.com") %>% req_auth_basic("user", "password")
  expect_snapshot(out <- req_dry_run(req))
  expect_equal(out$headers$authorization, redacted_sentinel())

  # unless specifically requested
  req <- request("http://example.com") %>% req_auth_basic("user", "password")
  expect_snapshot(out <- req_dry_run(req, redact_headers = FALSE))
  expect_equal(out$headers$authorization, "Basic dXNlcjpwYXNzd29yZA==")
})

test_that("doen't add space to urls (#567)", {
  req <- request("https://example.com/test:1:2")
  expect_output(req_dry_run(req), "test:1:2")
})
