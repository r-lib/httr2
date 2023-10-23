#' Iteration helpers
#'
#' @description
#' These functions are suitable for use with the `next_req` argument to
#' [req_perform_iteratively()]. Each implements iteration for a common
#' pagination pattern:
#'
#' * `iterate_with_offset()` increments a query parameter, e.g. `?page=1`,
#'   `?page=2`, or `?offset=1`, `offset=21`.
#' * `iterate_with_cursor()` updates a query parameter with the value of a
#'    cursor found somewhere in the response.
#'  * `iterate_with_link_url()` follows the url found the `Link` header.
#'    See `resp_link_url()` for more details.
#'
#' @param param_name Name of query parameter.
#' @param start Starting value.
#' @param offset Offset for each page.
#' @param resp_complete A callback function that takes a response (`resp`)
#'   and returns `TRUE` if there are no further pages.
#' @export
#' @examples
#' req <- request(example_url()) |>
#'   req_url_path("/iris") |>
#'   req_throttle(10) |>
#'   req_url_query(limit = 5)
#'
#' is_complete <- function(resp) {
#'   length(resp_body_json(resp)$data) == 0
#' }
#' resps <- req_perform_iteratively(
#'   req,
#'   iterate_with_offset("page_index", resp_complete = is_complete)
#' )
iterate_with_offset <- function(param_name,
                                start = 1,
                                offset = 1,
                                resp_complete = NULL) {
  check_string(param_name)
  check_number_whole(start)
  check_number_whole(offset, min = 1)
  check_function2(resp_complete, args = "resp", allow_null = TRUE)
  resp_complete <- resp_complete %||% function(resp) FALSE

  i <- start # assume already fetched
  function(resp, req) {
    if (!isTRUE(resp_complete(resp))) {
      i <<- i + offset
      req %>% req_url_query(!!param_name := i)
    }
  }
}

#' @rdname iterate_with_offset
#' @export
#' @param resp_param_value A callback function that takes a response (`resp`)
#'   and returns the next cursor value. Return `NULL` if there are no further
#'   pages.
iterate_with_cursor <- function(param_name, resp_param_value) {
  check_string(param_name)
  check_function2(resp_param_value, args = "resp")

  function(resp, req) {
    value <- resp_param_value(resp)
    if (!is.null(value)) {
      req %>% req_url_query(!!param_name := value)
    }
  }
}

#' @rdname iterate_with_offset
#' @export
#' @param rel The "link relation type" to use to retrieve the next page.
iterate_with_link_url <- function(rel = "next") {
  check_string(rel)

  function(resp, req) {
    url <- resp_link_url(resp, rel)
    if (!is.null(url)) {
      req %>% req_url(url)
    }
  }
}
