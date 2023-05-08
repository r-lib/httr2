request_test <- function(template = "/get", ...) {
  req <- request(example_url())
  req <- req_template(req, template, ..., .env = caller_env())
  req
}

#' URL too a local server that's useful for tests and examples
#'
#' Requires the webfakes package to be installed.
#'
#' @keywords internal
#' @export
example_url <- function() {
  check_installed("webfakes")

  env_cache(the, "test_app",
    webfakes::new_app_process(
      webfakes::httpbin_app(),
      opts = webfakes::server_opts(num_threads = 2)
    )
  )
  the$test_app$url()
}
