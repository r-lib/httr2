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
