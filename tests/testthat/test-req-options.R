test_that("can add and remove options", {
  req <- req("http://example.com")
  req <- req %>% req_options(x = 1)
  expect_equal(req$options, list(x = 1))
  req <- req %>% req_options(x = NULL)
  expect_equal(req$options, list())
})

test_that("can add header called req", {
  req <- req("http://example.com")
  req <- req %>% req_options(req = 1)
  expect_equal(req$options, list(req = 1))
})


# user_agent --------------------------------------------------------------

test_that("can override default user agent", {
  req1 <- req("http://example.com")
  req2 <- req1 %>% req_user_agent("abc")

  expect_equal(req_dry_run(req1)$headers$`user-agent`, default_ua())
  expect_equal(req_dry_run(req2)$headers$`user-agent`, "abc")
})

test_that("can send username/password", {
  user <- "u"
  password <- "p"
  req1 <- req_test("/basic-auth/:user/:password")
  req2 <- req1 %>% req_authenticate(user, password)

  expect_error(req_fetch(req1), class = "httr2_http_401")
  expect_error(req_fetch(req2), NA)
})

test_that("can set timeout", {
  req <- req_test("/delay/:secs", secs = 1) %>% req_timeout(0.1)
  expect_error(req_fetch(req), "timed out")
})

test_that("can request verbose record of request", {
  req <- req_test("/post") %>% req_body_raw("This is some text")

  # Snapshot test of what can be made reproducible
  req1 <- req %>%
    req_headers("Host" = "http://example.com") %>%
    req_verbose(header_in = FALSE)
  expect_snapshot_output(invisible(req_fetch(req1)))

  # Lightweight test for everything else
  req2 <- req %>% req_verbose(info = TRUE, data_in = TRUE)
  expect_output(req_fetch(req2))
})
