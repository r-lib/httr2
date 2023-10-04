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
        list(next_token = parsed$my_next_token, data = list(parsed))
      },
      set_token = function(req, next_token) {
        req_body_json(req, list(my_token = next_token))
      },
      n_pages = n_pages
    )
}


#' URL to a local server that's useful for tests and examples
#'
#' Requires the webfakes package to be installed. It has the following endpoints:
#'
#' * all the ones from the [webfakes::httpbin_app()]
#' * `/iris`: paginate through the iris dataset. It has the query parameters
#'   `page` and `limit` to control the pagination.
#'
#' @keywords internal
#' @export
example_url <- function() {
  check_installed("webfakes")

  app <- webfakes::httpbin_app()
  # paginated iris endpoint
  app$get("/iris", function(req, res) {
    page <- req$query$page
    if (is.null(page)) page <- 1L
    page <- as.integer(page)
    page_size <- req$query$limit
    if (is.null(page_size)) page_size <- 20L
    page_size <- as.integer(page_size)

    n <- nrow(iris)
    start <- (page - 1L) * page_size + 1L
    end <- min(start + page_size - 1L, n)
    ids <- seq(start, end)
    data <- vctrs::vec_slice(datasets::iris, ids)

    res$set_status(200L)$send_json(
      object = list(data = data, count = n),
      auto_unbox = TRUE,
      pretty = TRUE
    )
  })

  env_cache(the, "test_app",
    webfakes::new_app_process(
      app,
      opts = webfakes::server_opts(num_threads = 2)
    )
  )
  the$test_app$url()
}
