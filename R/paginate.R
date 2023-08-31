#' Pagination
#'
#' @inheritParams req_perform
#' @param next_request A callback function that takes a two arguments (the
#'   original request and the response) and returns:
#'
#'   * a new [request] to request the next page or
#'   * `NULL` if there is no next page.
#' @param page_size A parameter object that specifies how the page size is added
#'   to the request.
#' @param next_url A function that extracts the next url from the [response].
#' @param offset A function that applies that applies the new offset to the
#'   request. It takes two arguments: a [request] and an integer offset.
#' @param set_token A function that applies that applies the new token to the
#'   request. It takes two arguments: a [request] and the new token.
#' @param next_token A function that extracts the next token from the [response].
#' @param n_pages A function that extracts the next token from the [response].
#'
#' @return A modified HTTP [request].
#' @export
#'
#' @examples
#' request("https://pokeapi.co/api/v2/pokemon") %>%
#'   req_url_query(limit = 150) %>%
#'   req_paginate_next_url(
#'     next_url = function(resp) resp_body_json(resp)[["next"]],
#'     n_pages = function(resp) {
#'       calculate_n_pages(
#'         page_size = 150,
#'         total = resp_body_json(resp)$count
#'       )
#'     }
#'   )
req_paginate <- function(req,
                         next_request,
                         n_pages = NULL) {
  check_request(req)
  check_function2(next_request, args = c("resp", "req"))
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
#' @inheritParams req_perform
#' @param resp An HTTP [response].
#' @param max_pages The maximum number of pages to request.
#' @param progress Display a progress bar?
#'
#' @return A list of responses.
#' @export
#'
#' @examples
#' req_pokemon <- request("https://pokeapi.co/api/v2/pokemon") %>%
#'   req_url_query(limit = 150) %>%
#'   req_paginate_next_url(
#'     next_url = function(resp) resp_body_json(resp)[["next"]],
#'     n_pages = function(resp) {
#'       calculate_n_pages(
#'         page_size = 150,
#'         total = resp_body_json(resp)$count
#'       )
#'     }
#'   )
#'
#' responses <- paginate_perform(req_pokemon)
paginate_perform <- function(req,
                             max_pages = 20L,
                             progress = TRUE) {
  check_request(req)
  check_bool(progress)

  resp <- req_perform(req)
  f_n_pages <- req$policies$paginate$n_pages %||% function(resp) Inf
  n_pages <- min(f_n_pages(resp), max_pages)

  out <- vector("list", length = n_pages)
  out[[1]] <- resp

  cli::cli_progress_bar(
    "Paginate",
    total = n_pages,
    format = "{cli::pb_spin} Page {cli::pb_current}/{cli::pb_total} | ETA: {cli::pb_eta}",
    current = 1L
  )

  for (page in seq2(2, n_pages)) {
    req <- paginate_next_request(resp, req)
    if (is.null(req)) {
      page <- page - 1L
      break
    }

    resp <- req_perform(req)

    body_parsed <- resp_body_json(resp)
    out[[page]] <- resp

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

#' @rdname paginate_perform
paginate_next_request <- function(resp, req) {
  check_response(resp)
  check_request(req)

  if (!req_policy_exists(req, "paginate")) {
    cli::cli_abort(c(
      "{.arg req} doesn't have a pagination policy",
      i = "You can add pagination via `req_paginate()`."
    ))
  }

  next_request <- req$policies$paginate$next_request
  next_request(resp = resp, req = req)
}

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

#' @rdname req_paginate
#' @export
req_paginate_offset <- function(req,
                                offset,
                                page_size,
                                n_pages = NULL) {
  check_number_whole(page_size)
  check_function2(offset, args = c("req", "offset"))

  cur_offset <- 0L
  env <- current_env()
  next_request <- function(resp, req) {
    cur_offset <- get("cur_offset", envir = env)
    new_offset <- cur_offset + page_size
    assign("cur_offset", new_offset, envir = env)

    offset(req, new_offset)
  }

  req_paginate(
    req,
    next_request,
    n_pages
  )
}

#' @rdname req_paginate
#' @export
req_paginate_next_token <- function(req,
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

#' Calculate the number of pages
#'
#' @param page_size An integer.
#' @param total A function that extracts the total number of elements from the [response].
#'
#' @return A function that can be passed to the `n_pages` argument of [req_paginate()].
#' @export
#'
#' @examples
#' calculate_n_pages(page_size = 100, total = 250)
calculate_n_pages <- function(page_size, total) {
  check_number_whole(page_size)
  check_number_whole(total, allow_null = TRUE)
  if (is.null(total)) {
    return(NULL)
  }

  ceiling(total / page_size)
}
