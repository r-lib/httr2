request_test <- function(template = "/get", ...) {
  req <- request(test_server())
  req <- req_template(req, template, ..., .env = caller_env())
  req
}

#' A local server useful for tests and examples
#'
#' Requires the webfakes package to be installed.
#'
#' @keywords internal
#' @export
test_server <- function() {
  check_installed("webfakes")

  env_cache(the, "test_app",
    webfakes::new_app_process(
      webfakes::httpbin_app(),
      opts = webfakes::server_opts(num_threads = 2)
    )
  )
  the$test_app$url()
}
