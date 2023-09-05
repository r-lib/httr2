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
#' @param next_request A callback function that takes a two arguments (the
#'   original request and the response) and returns:
#'
#'   * a new [request] to request the next page or
#'   * `NULL` if there is no next page.
#' @param n_pages A function that extracts the total number of pages from
#'   the [response].
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
#'     next_url = function(resp) resp_body_json(resp)[["next"]],
#'     n_pages = function(resp) {
#'       total <- resp_body_json(resp)$count
#'       ceiling(total / page_size)
#'     }
#'   )
req_paginate <- function(req,
                         next_request,
                         n_pages = NULL) {
  check_request(req)
  check_function2(next_request, args = c("req", "resp"))
  check_function2(n_pages, args = "resp", allow_null = TRUE)

  req_policies(
    req,
    paginate = list(
      next_request = next_request,
      n_pages = n_pages
    )
  )
}

#' Perform a paginated request
#'
#' After preparing a paginated request with [req_paginate()] perform it with
#' [paginate_req_perform()]. In case the requests were interrupted, you can
#' get the intermediate results with [last_pagination_responses()] or
#' continue with [paginate_req_perform_continue].
#'
#' @inheritParams req_perform
#' @param resp An HTTP [response].
#' @param max_pages The maximum number of pages to request.
#' @param progress Display a progress bar?
#'
#' @return A list of responses.
#' @export
#'
#' @examples
#' page_size <- 150
#'
#' req_pokemon <- request("https://pokeapi.co/api/v2/pokemon") %>%
#'   req_url_query(limit = page_size) %>%
#'   req_paginate_next_url(
#'     next_url = function(resp) resp_body_json(resp)[["next"]],
#'     n_pages = function(resp) {
#'       total <- resp_body_json(resp)$count
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

  the$last_pagination_request <- req
  the$last_pagination_responses <- NULL
  the$last_pagination_page <- NULL
  the$last_pagination_n_pages <- NULL
  the$last_pagination_max_pages <- max_pages

  resp <- req_perform(req)
  f_n_pages <- req$policies$paginate$n_pages %||% function(resp) Inf
  n_pages <- f_n_pages(resp)
  the$last_pagination_n_pages <- f_n_pages(resp)
  # the implementation below doesn't really support an infinite amount of pages
  # but 100e3 should be plenty
  n_pages <- min(the$last_pagination_n_pages, max_pages, 100e3)

  the$last_pagination_responses <- vector("list", length = n_pages)
  the$last_pagination_responses[[1]] <- resp
  the$last_pagination_page <- 1

  paginate_perform_other_pages(
    page = 2,
    n_pages = n_pages,
    req = req,
    resp = resp
  )
}

paginate_perform_other_pages <- function(page, n_pages, req, resp) {
  cli::cli_progress_bar(
    "Paginate",
    total = n_pages,
    format = "{cli::pb_spin} Page {cli::pb_current}/{cli::pb_total} | ETA: {cli::pb_eta}",
    current = TRUE
  )

  for (page in seq2(page, n_pages)) {
    req <- paginate_next_request(resp, req)
    if (is.null(req)) {
      page <- page - 1L
      break
    }

    resp <- req_perform(req)
    the$last_pagination_page <- page

    body_parsed <- resp_body_json(resp)
    the$last_pagination_responses[[page]] <- resp

    cli::cli_progress_update(set = page)
  }
  cli::cli_progress_done()

  # remove unused end of `out` in case the pagination loop exits before all
  # `max_pages` is reached
  if (page < n_pages) {
    the$last_pagination_responses <- the$last_pagination_responses[seq2(1, page)]
  }

  the$last_pagination_responses
}

#' @export
#' @rdname last_response
last_pagination_responses <- function() {
  the$last_pagination_responses
}

#' @export
#' @rdname paginate_req_perform
paginate_req_perform_continue <- function(max_pages = NULL) {
  page <- the$last_pagination_page
  req <- the$last_pagination_request
  max_pages <- max_pages %||% the$last_pagination_max_pages

  if (is.null(page)) {
    out <- paginate_req_perform(
      req = req,
      max_pages = max_pages
    )
    return(out)
  }

  resp <- the$last_pagination_responses[[page]]

  n_pages <- min(the$last_pagination_n_pages, max_pages, 100e3)

  paginate_perform_other_pages(
    page = page + 1,
    n_pages = n_pages,
    req = req,
    resp = resp
  )
}

#' @export
#'
#' @rdname paginate_req_perform
paginate_next_request <- function(resp, req) {
  check_response(resp)
  check_request(req)
  check_has_pagination_policy(req)

  next_request <- req$policies$paginate$next_request
  next_request(resp = resp, req = req)
}

#' @param next_url A function that extracts the url to the next page from the
#'   [response].
#' @rdname req_paginate
#' @export
req_paginate_next_url <- function(req,
                                  next_url,
                                  n_pages = NULL) {
  check_function2(next_url, args = "resp")

  next_request <- function(req, resp) {
    next_url <- next_url(resp)

    if (is.null(next_url)) {
      return(NULL)
    }

    req_url(req, next_url)
  }

  req_paginate(
    req,
    next_request,
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
                                n_pages = NULL) {
  check_function2(offset, args = c("req", "offset"))
  check_number_whole(page_size)

  next_request <- function(req, resp) {
    cur_offset <- req$policies$paginate$offset
    cur_offset <- cur_offset + page_size
    req$policies$paginate$offset <- cur_offset
    offset(req, cur_offset)
  }

  out <- req_paginate(
    req,
    next_request,
    n_pages
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
                               n_pages = NULL) {
  check_function2(set_token, args = c("req", "token"))
  check_function2(next_token, args = "resp")

  next_request <- function(req, resp) {
    next_token <- next_token(resp)

    if (is.null(next_token)) {
      return(NULL)
    }

    set_token(req, next_token)
  }

  req_paginate(
    req,
    next_request,
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
