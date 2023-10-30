#' Iteration helpers
#'
#' @description
#' These functions are intended for use with the `next_req` argument to
#' [req_perform_iterative()]. Each implements iteration for a common
#' pagination pattern:
#'
#' * `iterate_with_offset()` increments a query parameter, e.g. `?page=1`,
#'   `?page=2`, or `?offset=1`, `offset=21`.
#' * `iterate_with_cursor()` updates a query parameter with the value of a
#'    cursor found somewhere in the response.
#'  * `iterate_with_link_url()` follows the url found in the `Link` header.
#'    See `resp_link_url()` for more details.
#'
#' @param param_name Name of query parameter.
#' @param start Starting value.
#' @param offset Offset for each page. The default is set to `1` so you get
#'   (e.g.) `?page=1`, `?page=2`, ... If `param_name` refers to an element
#'   index (rather than a page index) you'll want to set this to a larger number
#'   so you get (e.g.) `?items=20`, `?items=40`, ...
#' @param resp_complete A callback function that takes a response (`resp`)
#'   and returns `TRUE` if there are no further pages.
#' @param resp_pages A callback function that takes a response (`resp`) and
#'   returns the total number of pages, or `NULL` if unknown. It will only
#'   be called once.
#' @export
#' @examples
#' req <- request(example_url()) |>
#'   req_url_path("/iris") |>
#'   req_throttle(10) |>
#'   req_url_query(limit = 50)
#'
#' # If you don't know the total number of pages in advance, you can
#' # provide a `resp_complete()` callback
#' is_complete <- function(resp) {
#'   length(resp_body_json(resp)$data) == 0
#' }
#' resps <- req_perform_iterative(
#'   req,
#'   next_req = iterate_with_offset("page_index", resp_complete = is_complete),
#'   max_reqs = Inf
#' )
#'
#' \dontrun{
#' # Alternatively, if the response returns the total number of pages (or you
#' # can easily calculate it), you can use the `resp_pages()` callback which
#' # will generate a better progress bar.
#'
#' resps <- req_perform_iterative(
#'   req %>% req_url_query(limit = 1),
#'   next_req = iterate_with_offset(
#'     "page_index",
#'     resp_pages = function(resp) resp_body_json(resp)$pages
#'   ),
#'   max_reqs = Inf
#' )
#' }
iterate_with_offset <- function(param_name,
                                start = 1,
                                offset = 1,
                                resp_pages = NULL,
                                resp_complete = NULL) {
  check_string(param_name)
  check_number_whole(start)
  check_number_whole(offset, min = 1)
  check_function2(resp_pages, args = "resp", allow_null = TRUE)
  check_function2(resp_complete, args = "resp", allow_null = TRUE)
  resp_complete <- resp_complete %||% function(resp) FALSE

  known_total <- FALSE
  i <- start # assume already fetched first page

  function(resp, req) {
    if (!is.null(resp_pages) && !known_total) {
      n <- resp_pages(resp)
      if (!is.null(n)) {
        known_total <<- TRUE
        signal_total_pages(n)
      }
    }

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


#' Signal total number pages
#'
#' To be called within a `next_req` callback function used with
#' [req_perform_iterative()]
#'
#' @param n Total number of pages.
#' @export
#' @keywords internal
signal_total_pages <- function(n) {
  if (is.null(n)) {
    return()
  }

  check_number_whole(n, min = 1)
  signal("", class = "httr2_total_pages", n = n)
}
