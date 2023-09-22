#' Pagination
#'
#' Use `req_paginate()` to specify how to request the next page in a paginated
#' API. Use [paginate_req_perform()] to fetch all pages.
#' If you need more control use a combination of [req_perform()] and
#' [paginate_next_request()] to iterate through the pages yourself.
#' There are also helpers for common pagination patterns:
#'   * `req_paginate_next_url()` when the response contains a link to the next
#'     page.
#'   * `req_paginate_offset()` when the request describes the offset i.e.
#'     at which element to start and the page size.
#'   * `req_paginate_next_token()` when the response contains a token
#'     that is used to describe the next page.
#'
#' @inheritParams req_perform
#' @param next_request A callback function that returns a [request] to the next
#'   page or `NULL` if there is no next page. It takes a three arguments:
#'
#'   1. `req`: the previous request.
#'   2. `resp`: the response of the current request.
#'   3. `parsed`: the result of the argument `parse_resp`.
#' @param parse_resp A function with one argument `resp` that parses the
#'   response. The result is passed to the argument `parsed` of `next_request()` and
#'   `n_pages()`. This helps to avoid parsing the response multiple times.
#' @param n_pages An optional function that extracts the total number of pages, improving the
#'   automatically generated progress bar. It has two arguments:
#'
#'   1. `resp`: the response of the current request.
#'   2. `parsed`: the result of the argument `parse_resp`.
#'
#' @return A modified HTTP [request].
#' @seealso [paginate_req_perform()] to fetch all pages. [paginate_next_request()]
#'   to generate the request to the next page.
#' @export
#'
#' @examples
#' page_size <- 150
#'
#' request("https://pokeapi.co/api/v2/pokemon") %>%
#'   req_url_query(limit = page_size) %>%
#'   req_paginate_next_url(
#'     parse_resp = resp_body_json,
#'     next_url = function(resp, parsed) parsed[["next"]],
#'     n_pages = function(resp, parsed) {
#'       total <- parsed$count
#'       ceiling(total / page_size)
#'     }
#'   )
req_paginate <- function(req,
                         next_request,
                         parse_resp = NULL,
                         n_pages = NULL) {
  check_request(req)
  check_function2(next_request, args = c("req", "resp", "parsed"))
  check_function2(parse_resp, args = "resp", allow_null = TRUE)
  parse_resp <- parse_resp %||% identity
  check_function2(n_pages, args = c("resp", "parsed"), allow_null = TRUE)
  n_requests <- NULL
  get_n_requests <- n_pages %||% function(resp, parsed) Inf

  req_policies(
    req,
    parse_resp = parse_resp,
    multi = list(
      next_request = next_request,
      n_requests = n_requests,
      get_n_requests = get_n_requests
    )
  )
}

#' @export
#' @rdname paginate_req_perform
paginate_next_request <- function(resp, req, parsed) {
  check_response(resp)
  check_request(req)
  check_has_pagination_policy(req)

  next_request <- req$policies$multi$next_request
  next_request(
    resp = resp,
    req = req,
    parsed = parsed
  )
}

#' @param next_url A function that extracts the url to the next page. It takes
#'   two arguments:
#'
#'   1. `resp`: the response of the current request.
#'   2. `parsed`: the result of the argument `parse_resp`.
#' @rdname req_paginate
#' @export
req_paginate_next_url <- function(req,
                                  next_url,
                                  parse_resp = NULL,
                                  n_pages = NULL) {
  check_function2(next_url, args = c("resp", "parsed"))

  next_request <- function(req, resp, parsed) {
    next_url <- next_url(resp, parsed)

    if (is.null(next_url)) {
      return(NULL)
    }

    req_url(req, next_url)
  }

  req_paginate(
    req,
    next_request,
    parse_resp = parse_resp,
    n_pages = n_pages
  )
}

#' @param set_token A function that applies the new token to the request. It
#'   takes two arguments: a [request] and the new token.
#'
#'   1. `req`: the previous request.
#'   2. `token`: the token for the next page.
#' @param next_token A function that extracts the next token from the [response].
#' @rdname req_paginate
#' @export
req_paginate_token <- function(req,
                               set_token,
                               next_token,
                               parse_resp = NULL,
                               n_pages = NULL) {
  check_function2(set_token, args = c("req", "token"))
  check_function2(next_token, args = c("resp", "parsed"))

  next_request <- function(req, resp, parsed) {
    next_token <- next_token(resp, parsed)

    if (is.null(next_token)) {
      return(NULL)
    }

    set_token(req, next_token)
  }

  req_paginate(
    req,
    next_request,
    parse_resp = parse_resp,
    n_pages = n_pages
  )
}

#' @param offset A function that applies the new offset to the request. It takes
#'   two arguments:
#'
#'   1. `req`: the previous request.
#'   2. `offset`: the integer offset for the next page.
#' @param page_size A whole number that specifies the page size i.e. the number
#'   of elements per page.
#' @rdname req_paginate
#' @export
req_paginate_offset <- function(req,
                                offset,
                                page_size,
                                parse_resp = NULL,
                                n_pages = NULL) {
  check_function2(offset, args = c("req", "offset"))
  check_number_whole(page_size)

  next_request <- function(req, resp, parsed) {
    cur_offset <- req$policies$multi$offset
    cur_offset <- cur_offset + page_size
    req$policies$multi$offset <- cur_offset
    offset(req, cur_offset)
  }

  out <- req_paginate(
    req,
    next_request,
    parse_resp = parse_resp,
    n_pages = n_pages
  )

  out$policies$multi$offset <- 0L
  out
}

#' @param page_index A function that applies the page index to the request. It
#'   takes two arguments:
#'
#'   1. `req`: the previous request.
#'   2. `offset`: the integer page index for the next page.
#' @rdname req_paginate
#' @export
req_paginate_page_index <- function(req,
                                    page_index,
                                    parse_resp = NULL,
                                    n_pages = NULL) {
  check_function2(page_index, args = c("req", "page"))

  next_request <- function(req, resp, parsed) {
    new_page <- req$policies$multi$page + 1L
    req$policies$multi$page <- new_page
    page_index(req, new_page)
  }

  out <- req_paginate(
    req,
    next_request,
    parse_resp = parse_resp,
    n_pages = n_pages
  )

  out$policies$multi$page <- 1L
  out
}
