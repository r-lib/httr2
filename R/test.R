req_test <- function(template, ...) {
  if (is.null(the$test_app)) {
    the$test_app <- webfakes::new_app_process(webfakes::httpbin_app())
  }

  req <- req(the$test_app$url())
  req <- req_template(req, template, ...)
  req
}

req_httpbin <- function(template) {
  req <- req("https://httpbin.org")
  req <- req_template(req, template)
  req
}

