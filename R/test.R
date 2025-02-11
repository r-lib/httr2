request_test <- function(template = "/get", ...) {
  req <- request(example_url())
  req <- req_template(req, template, ..., .env = caller_env())
  req
}

#' Code for examples
#'
#' @description
#' `example_url()` runs a simple websever using the webfakes package with the
#' following endpoints:
#'
#' * all the ones from the [webfakes::httpbin_app()]
#' * `/iris`: paginate through the iris dataset. It has the query parameters
#'   `page` and `limit` to control the pagination.
#'
#' `example_github_client()` is an OAuth client for GitHub.
#'
#' @keywords internal
#' @export
example_url <- function(path = "/") {
  check_installed("webfakes")
  if (is_testing() && !is_interactive()) {
    testthat::skip_on_covr()
  }
  env_cache(the, "test_app", example_app())
  the$test_app$url(path)
}

example_app <- function() {
  app <- webfakes::httpbin_app()
  # paginated iris endpoint
  app$get("/iris", function(req, res) {
    page <- req$query$page
    if (is.null(page)) page <- 1L
    page <- as.integer(page)
    page_size <- req$query$limit
    if (is.null(page_size)) page_size <- 20L
    page_size <- as.integer(page_size)

    n <- nrow(datasets::iris)
    start <- (page - 1L) * page_size + 1L
    end <- start + page_size - 1L
    ids <- rlang::seq2(start, end)
    data <- vctrs::vec_slice(datasets::iris, intersect(ids, seq_len(n)))

    res$set_status(200L)$send_json(
      object = list(data = data, count = n, pages = ceiling(n / page_size)),
      auto_unbox = TRUE,
      pretty = TRUE
    )
  })

  webfakes::new_app_process(
    app,
    opts = webfakes::server_opts(num_threads = 20, enable_keep_alive = TRUE)
  )
}

#' @export
#' @rdname example_url
example_github_client <- function() {
  # <https://github.com/settings/applications/1636322>
  oauth_client(
    id = "28acfec0674bb3da9f38",
    secret = obfuscated(paste0(
       "J9iiGmyelHltyxqrHXW41ZZPZamyUNxSX1_uKnv",
       "PeinhhxET_7FfUs2X0LLKotXY2bpgOMoHRCo"
    )),
    token_url = "https://github.com/login/oauth/access_token",
    name = "hadley-oauth-test"
  )
}
