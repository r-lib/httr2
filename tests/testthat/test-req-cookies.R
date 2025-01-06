test_that("can read/write cookies", {
  cookie_path <- withr::local_tempfile()

  set_cookie <- function(req, name, value) {
    request_test("/cookies/set/:name/:value", name = name, value = value) %>%
      req_cookie_preserve(cookie_path) %>%
      req_perform()
  }
  set_cookie(req, "x", "a")
  set_cookie(req, "y", "b")
  set_cookie(req, "z", "c")

  expect_snapshot(readLines(cookie_path)[-(1:4)])

  cookies <- request_test("/cookies") %>%
    req_cookie_preserve(cookie_path) %>%
    req_perform() %>%
    resp_body_json() %>%
    .$cookies
  expect_mapequal(cookies, list(x = "a", y = "b", z = "c"))
})

test_that("can set cookies", {
  resp <- request(example_url()) %>%
    req_cookies_set(a = 1, b = 1) %>%
    req_url_relative("/cookies") %>%
    req_perform()

  expect_equal(resp_body_json(resp), list(cookies = list(a = "1", b = "1")))
})

test_that("cookie values are usually escaped", {
  resp <- request(example_url()) %>%
    req_cookies_set(a = I("%20"), b = "%") %>%
    req_url_relative("/cookies") %>%
    req_perform()

  expect_equal(resp_body_json(resp), list(cookies = list(a = "%20", b = "%25")))
})
