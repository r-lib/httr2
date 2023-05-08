request_test <- function(template = "/get", ...) {
  if (is.null(the$test_app)) {
    the$test_app <- webfakes::new_app_process(
      webfakes::httpbin_app(),
      opts = webfakes::server_opts(num_threads = 6)
    )
  }

  req <- request(the$test_app$url())
  req <- req_template(req, template, ..., .env = caller_env())
  req
}
