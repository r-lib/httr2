test_that("can add and remove options", {
  req <- request("http://example.com")
  req <- req %>% req_options(x = 1)
  expect_equal(req$options, list(x = 1))
  req <- req %>% req_options(x = NULL)
  expect_equal(req$options, list())
})

test_that("can add header called req", {
  req <- request("http://example.com")
  req <- req %>% req_options(req = 1)
  expect_equal(req$options, list(req = 1))
})

test_that("default user agent includes httr2 + libcurl versions", {
  req <- request("http://example.com") %>% req_user_agent()

  expect_match(req$options$useragent, "httr2")
  expect_match(req$options$useragent, "libcurl")
})

test_that("can override default user agent", {
  req <- request("http://example.com") %>% req_user_agent("abc")
  expect_equal(req$options$useragent, "abc")
})

test_that("default user agent works with dev curl", {
  # non-R-ish library version for curl, #416
  local_mocked_bindings(curl_system_version = function(...) "8.4.0-DEV")

  expect_match(default_user_agent(), "libcurl/8.4.0-DEV")
})

test_that("can set timeout", {
  req <- request_test("/delay/:secs", secs = 1) %>% req_timeout(0.1)
  expect_error(req_perform(req), "timed out")
})

test_that("validates inputs", {
  expect_snapshot(error = TRUE, {
    request_test() %>% req_timeout("x")
    request_test() %>% req_timeout(0)
  })
})

test_that("req_proxy gives helpful errors", {
  req <- request_test("/get")
  expect_snapshot(error = TRUE, {
    req %>% req_proxy(port = "abc")
    req %>% req_proxy("abc", auth = "bsc")
  })
})

test_that("auth_flags gives correct constant", {
  expect_equal(auth_flags("digest"), 2)
  expect_equal(auth_flags("ntlm"), 8)
  expect_equal(auth_flags("any"), -17)
})
