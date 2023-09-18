#' Pagination
#'
#' Use `req_paginate()` to specify how to request the next page in a paginated
#' API. Use [paginate_req_perform()] to fetch all pages.
#' If you need more control use a combination of [req_perform()] and
#' [paginate_next_request()] to iterate through the pages yourself.
#' There are also helpers for common pagination patterns:
#'   * `req_paginate_next_url()` when the response contains a link to the next
#'     page. The `parse_resp()` function
#'   * `req_paginate_offset()` when the request describes the offset i.e.
#'     at which element to start and the page size.
#'   * `req_paginate_next_token()` when the response contains a token
#'     that is used to describe the next page.
#'
#' @inheritParams req_perform
#' @param next_request A callback function that returns a [request] to the next
#'   page or `NULL` if there is no next page. It takes a two arguments:
#'
#'   1. `req`: the previous request.
#'   2. `parsed`: the result of the argument `parse_resp`.
#' @param parse_resp A function with one argument `resp` that parses the
#'   response and returns a list with the field `data` and other fields needed
#'   to create the request for the next page.
#'   `paginate_req_perform()` combines all `data` fields via [vctrs::vec_c()]
#'   and returns the result.
#'   Other fields that might be needed are:
#'
#'     * `next_url` for `paginate_next_url()`.
#'     * `next_token` for `paginate_next_token()`.
#'
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
#'     parse_resp = function(resp) {
#'       parsed <- resp_body_json(resp)
#'       results <- parsed$results
#'       data <- data.frame(
#'         name = sapply(results, `[[`, "name"),
#'         url = sapply(results, `[[`, "url")
#'       )
#'
#'       list(data = data, next_url = parsed$`next`)
#'     },
#'     n_pages = function(parsed) {
#'       total <- parsed$count
#'       ceiling(total / page_size)
#'     }
#'   )
req_paginate <- function(req,
                         next_request,
                         parse_resp = NULL,
                         n_pages = NULL) {
  check_request(req)
  check_function2(next_request, args = c("req", "parsed"))
  check_function2(parse_resp, args = "resp", allow_null = TRUE)
  parse_resp <- parse_resp %||% function(resp) list(data = resp)
  check_function2(n_pages, args = "parsed", allow_null = TRUE)
  n_pages <- n_pages %||% function(parsed) Inf

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
#' @param parsed The response parsed by the argument `parse_resp` of [req_paginate()].
#' @param max_pages The maximum number of pages to request.
#' @param progress Display a progress bar? Use `TRUE` to turn on a basic progress
#'   bar, use a string to give it a name, or see [progress_bars] for more details.
#'
#' @return The result of `vec_c()`ing together the `data` fields that were
#'   extracted by the `parse_resp()` argument of [req_paginate()].
#'   If this argument is not specified, it will be a list of the raw responses.
#' @export
#'
#' @examples
#' page_size <- 150
#'
#' req_pokemon <- request("https://pokeapi.co/api/v2/pokemon") %>%
#'   req_url_query(limit = page_size) %>%
#'   req_paginate_next_url(
#'     parse_resp = function(resp) {
#'       parsed <- resp_body_json(resp)
#'       results <- parsed$results
#'       data <- data.frame(
#'         name = sapply(results, `[[`, "name"),
#'         url = sapply(results, `[[`, "url")
#'       )
#'
#'       list(data = data, next_url = parsed$`next`)
#'     },
#'     n_pages = function(parsed) {
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

  resp <- req_perform(req)
  parse_resp <- req$policies$paginate$parse_resp
  parsed <- parse_resp(resp)

  f_n_pages <- req$policies$paginate$n_pages

  n_pages <- min(f_n_pages(parsed), max_pages)
  pb <- create_progress_bar(
    total = n_pages,
    name = "Paginate",
    config = progress
  )
  show_progress <- !is.null(pb)

  # the implementation below doesn't really support an infinite amount of pages
  # but 100e3 should be plenty
  if (is.infinite(n_pages)) {
    n_pages <- 100e3
  }

  out <- vector("list", length = n_pages)
  out[[1]] <- parsed$data

  for (page in seq2(2, n_pages)) {
    req <- paginate_next_request(req, parsed)
    if (is.null(req)) {
      page <- page - 1L
      break
    }

    resp <- req_perform(req)
    parsed <- parse_resp(resp)

    out[[page]] <- parsed$data

    if (show_progress) cli::cli_progress_update()
  }
  if (show_progress) cli::cli_progress_done()

  # `page` may be `NULL` if `start >= n_pages`
  page <- page %||% 1L

  # remove unused end of `out` in case the pagination loop exits before all
  # `max_pages` is reached
  if (page < n_pages) {
    out <- out[seq2(1, page)]
  }

  vctrs::list_unchop(out)
}

#' @export
#' @rdname paginate_req_perform
paginate_next_request <- function(req, parsed) {
  check_request(req)
  check_has_pagination_policy(req)

  next_request <- req$policies$paginate$next_request
  next_request(
    req = req,
    parsed = parsed
  )
}

#' @rdname req_paginate
#' @export
req_paginate_next_url <- function(req,
                                  parse_resp,
                                  n_pages = NULL) {
  next_request <- function(req, parsed) {
    next_url <- parsed[["next_url"]]

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

  next_request <- function(req, parsed) {
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
#' @rdname req_paginate
#' @export
req_paginate_token <- function(req,
                               parse_resp,
                               set_token,
                               n_pages = NULL) {
  check_function2(set_token, args = c("req", "next_token"))

  next_request <- function(req, parsed) {
    next_token <- parsed[["next_token"]]

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
