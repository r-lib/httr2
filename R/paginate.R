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
  n_pages <- n_pages %||% function(resp, parsed) Inf

  req_policies(
    req,
    paginate = list(
      next_request = next_request,
      parse_resp = parse_resp,
      n_pages = n_pages
    )
  )
}

#' Perform a paginated request
#'
#' @inheritParams req_perform
#' @param resp An HTTP [response].
#' @param parsed The response parsed by the argument `parse_resp` of [req_paginate()].
#' @param max_pages The maximum number of pages to request.
#' @param progress Display a progress bar?
#'
#' @return A list of responses parsed with the `parse_resp` argument of
#'   [req_paginate()]. If this argument is not specified, it will be a list of responses.
#' @export
#'
#' @examples
#' page_size <- 150
#'
#' req_pokemon <- request("https://pokeapi.co/api/v2/pokemon") %>%
#'   req_url_query(limit = page_size) %>%
#'   req_paginate_next_url(
#'     next_url = function(resp, parsed) parsed[["next"]],
#'     parse_resp = resp_body_json,
#'     n_pages = function(resp, parsed) {
#'       total <- parsed$count
#'       ceiling(total / page_size)
#'     }
#'   )
#'
#' responses <- paginate_req_perform(req_pokemon)
paginate_req_perform <- function(req,
                                 max_pages = 20L,
                                 progress = TRUE) {
  check_request(req)
  check_has_pagination_policy(req)
  check_number_whole(max_pages, allow_infinite = TRUE, min = 1)
  check_bool(progress)

  resp <- req_perform(req)
  parsed <- paginate_parse_response(resp, req)

  f_n_pages <- req$policies$paginate$n_pages

  n_pages <- min(f_n_pages(resp, parsed), max_pages)
  # the implementation below doesn't really support an infinite amount of pages
  # but 100e3 should be plenty
  if (is.infinite(n_pages)) {
    n_pages <- 100e3
  }

  out <- vector("list", length = n_pages)
  out[[1]] <- parsed

  cli::cli_progress_bar(
    "Paginate",
    total = n_pages,
    format = "{cli::pb_spin} Page {cli::pb_current}/{cli::pb_total} | ETA: {cli::pb_eta}",
    current = 1L
  )

  for (page in seq2(2, n_pages)) {
    req <- paginate_next_request(resp, req, parsed)
    if (is.null(req)) {
      page <- page - 1L
      break
    }

    resp <- req_perform(req)
    parsed <- paginate_parse_response(resp, req)

    out[[page]] <- parsed

    cli::cli_progress_update()
  }
  cli::cli_progress_done()

  # remove unused end of `out` in case the pagination loop exits before all
  # `max_pages` is reached
  if (page < n_pages) {
    out <- out[seq2(1, page)]
  }

  out
}

#' @export
#'
#' @rdname paginate_req_perform
paginate_next_request <- function(resp, req, parsed) {
  check_response(resp)
  check_request(req)
  check_has_pagination_policy(req)

  next_request <- req$policies$paginate$next_request
  next_request(
    resp = resp,
    req = req,
    parsed = parsed
  )
}

paginate_parse_response <- function(resp, req) {
  parse_resp <- req$policies$paginate$parse_resp
  if (is.null(parse_resp)) {
    return(NULL)
  }

  parse_resp(resp)
}

#' @param next_url A function that extracts the url to the next page from the
#'   [response] and the `body`.
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

#' @param offset A function that applies the new offset to the request. It takes
#'   two arguments: a [request] and an integer offset.
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
    cur_offset <- req$policies$paginate$offset
    cur_offset <- cur_offset + page_size
    req$policies$paginate$offset <- cur_offset
    offset(req, cur_offset)
  }

  out <- req_paginate(
    req,
    next_request,
    parse_resp = parse_resp,
    n_pages = n_pages
  )

  out$policies$paginate$offset <- 0L
  out
}

#' @param set_token A function that applies the new token to the request. It
#'   takes two arguments: a [request] and the new token.
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

check_has_pagination_policy <- function(req, call = caller_env()) {
  if (!req_policy_exists(req, "paginate")) {
    cli::cli_abort(c(
      "{.arg req} doesn't have a pagination policy.",
      i = "You can add pagination via `req_paginate()`."
    ))
  }
}
