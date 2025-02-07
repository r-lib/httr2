test_that("req_dry_run() returns useful data", {
  resp <- request("http://example.com") %>% req_dry_run(quiet = TRUE)
  expect_equal(resp$method, "GET")
  expect_equal(resp$path, "/")
  expect_match(resp$headers$`user-agent`, "libcurl")
})

test_that("body is shown", {
  req <- request("http://example.com") %>%
    req_headers(`Accept-Encoding` = "", `User-Agent` = "")

  expect_snapshot({
    req %>%
      req_body_json(list(x = 1, y = TRUE, z = "c")) %>%
      req_dry_run()
  })

  # even if it contains unicode
  expect_snapshot({
    req %>%
      req_body_raw("Cenário") %>%
      req_dry_run()
  })
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
