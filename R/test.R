request_test <- function(template = "/get", ...) {
  req <- request(example_url())
  req <- req_template(req, template, ..., .env = caller_env())
  req
}

token_body_test <- function(token = NULL) {
  compact(list(x = list(1), my_next_token = token))
}

request_pagination_test <- function(parse_resp = NULL,
                                    n_pages = NULL,
                                    local_env = caller_env()) {
  local_mocked_responses(function(req) {
    cur_token <- req$body$data$my_token %||% 1L
    response_json(body = token_body_test(if (cur_token != 4) cur_token + 1))
  }, env = local_env)

  request_test() %>%
    req_paginate_token(
      parse_resp = parse_resp %||% function(resp) {
        parsed <- resp_body_json(resp)
        list(next_token = parsed$my_next_token, data = parsed)
      },
      set_token = function(req, next_token) {
        req_body_json(req, list(my_token = next_token))
      },
      n_pages = n_pages
    )
}


#' URL to a local server that's useful for tests and examples
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
