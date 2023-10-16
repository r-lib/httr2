#' Define a paginated request
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Use `req_paginate()` to specify how to request the next page in a paginated
#' API. Use [req_perform_iteratively()] to fetch all pages.
#' If you need more control use a combination of [req_perform()] and
#' [iterate_next_request()] to iterate through the pages yourself.
#'
#' There are also helpers for common pagination patterns:
#'   * `req_paginate_next_url()` when the response contains a link to the next
#'     page.
#'   * `req_paginate_next_token()` when the response contains a token
#'     that is used to describe the next page.
#'   * `req_paginate_offset()` when the request describes the offset i.e.
#'     at which element to start and the page size.
#'   * `req_paginate_page_index()` when the request specifies which the page to
#'     request via an index.
#'
#' @inheritParams req_perform
#' @param next_request A callback function that returns a [request] to the next
#'   page or `NULL` if there is no next page. It takes two arguments:
#'
#'   1. `req`: the previous request.
#'   2. `parsed`: the previous response parsed via the argument `parse_resp`.
#' @param parse_resp A function with one argument `resp` that parses the
#'   response and returns a list with the field `data` and other fields needed
#'   to create the request for the next page.
#'   `req_perform_iteratively()` combines all `data` fields via [vctrs::vec_c()]
#'   and returns the result.
#'   Other fields that might be needed are:
#'
#'     * `next_url` for `paginate_next_url()`.
#'     * `next_token` for `paginate_next_token()`.
#'
#' @param required_fields An optional character vector that specifies which
#'   fields are required in the list returned by `parse_resp()`.
#' @param n_pages An optional function that extracts the total number of pages, improving the
#'   automatically generated progress bar. It has one argument `parsed`, which
#'   is the previous response parsed via the argument `parse_resp`.
#'
#' @return A modified HTTP [request].
#' @seealso [req_perform_iteratively()] to fetch all pages. [iterate_next_request()]
#'   to generate the request to the next page.
#' @export
#'
#' @examples
#' page_size <- 40
#'
#' request(example_url()) |>
#'   req_url_path("/iris") |>
#'   req_url_query(limit = page_size) |>
#'   req_paginate_page_index(
#'     page_index = function(req, page) {
#'       req |> req_url_query(page_index = page)
#'     },
#'     parse_resp = function(resp) {
#'       parsed <- resp_body_json(resp)
#'       results <- parsed$data
#'       data <- data.frame(
#'         Sepal.Length = sapply(results, `[[`, "Sepal.Length"),
#'         Sepal.Width = sapply(results, `[[`, "Sepal.Width"),
#'         Petal.Length = sapply(results, `[[`, "Petal.Length"),
#'         Petal.Width = sapply(results, `[[`, "Petal.Width"),
#'         Species = sapply(results, `[[`, "Species")
#'       )
#'
#'       list(data = data, count = parsed$count)
#'     },
#'     n_pages = function(parsed) {
#'       total <- parsed$count
#'       ceiling(total / page_size)
#'     }
#'   )
req_paginate <- function(req,
                         next_request,
                         parse_resp = NULL,
                         required_fields = NULL,
                         n_pages = NULL) {
  check_request(req)
  check_function2(next_request, args = c("req", "parsed"))
  check_function2(parse_resp, args = "resp", allow_null = TRUE)
  parse_resp <- parse_resp %||% function(resp) list(data = resp)
  check_character(required_fields, allow_null = TRUE)
  required_fields <- union(required_fields, "data")
  check_function2(n_pages, args = "parsed", allow_null = TRUE)
  n_pages <- n_pages %||% function(parsed) Inf

  wrapped_parse_resp <- function(resp) {
    out <- parse_resp(resp)
    vctrs::obj_check_list(out, arg = "parse_resp(resp)")

    missing_fields <- setdiff(required_fields, names2(out))
    if (!is_empty(missing_fields)) {
      cli::cli_abort(c("The list returned by {.code parse_resp(resp)} is missing the field{?s} {.field {missing_fields}}."))
    }

    out
  }

  req_policies(
    req,
    paginate = list(
      next_request = next_request,
      parse_resp = wrapped_parse_resp,
      required_fields = required_fields,
      n_pages = n_pages
    )
  )
}

#' Perform requests iteratively, generating new requests from previous responses
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `req_perform_iteratively()` requests all pages for an iterated request and
#' returning a list of responses.
#'
#' @inheritParams req_perform
#' @param max_pages The maximum number of pages to request.
#' @param progress Display a progress bar? Use `TRUE` to turn on a basic progress
#'   bar, use a string to give it a name, or see [progress_bars] for more details.
#'
#' @return The result of `vec_c()`ing together the `data` fields that were
#'   extracted by the `parse_resp` argument of [req_paginate()].
#'   If `parse_resp` is not specified, it will be a list of the raw responses.
#' @export
#'
#' @examples
#' page_size <- 40
#'
#' req_flowers <- request(example_url()) |>
#'   req_url_path("/iris") |>
#'   req_url_query(limit = page_size) |>
#'   req_paginate_page_index(
#'     page_index = function(req, page) {
#'       req |> req_url_query(page_index = page)
#'     },
#'     parse_resp = function(resp) {
#'       parsed <- resp_body_json(resp)
#'       results <- parsed$data
#'       data <- data.frame(
#'         Sepal.Length = sapply(results, `[[`, "Sepal.Length"),
#'         Sepal.Width = sapply(results, `[[`, "Sepal.Width"),
#'         Petal.Length = sapply(results, `[[`, "Petal.Length"),
#'         Petal.Width = sapply(results, `[[`, "Petal.Width"),
#'         Species = sapply(results, `[[`, "Species")
#'       )
#'
#'       list(data = data, count = parsed$count)
#'     },
#'     n_pages = function(parsed) {
#'       total <- parsed$count
#'       ceiling(total / page_size)
#'     }
#'   )
#'
#' req_perform_iteratively(req_flowers)
req_perform_iteratively <- function(req,
                                    max_pages = 20L,
                                    progress = TRUE) {
  check_request(req)
  check_has_pagination_policy(req)
  check_number_whole(max_pages, allow_infinite = TRUE, min = 1)

  parse_resp <- req$policies$paginate$parse_resp
  f_n_pages <- req$policies$paginate$n_pages

  # the implementation below doesn't really support an infinite amount of pages
  # but 100e3 should be plenty
  n_pages <- max_pages
  if (is.infinite(n_pages)) {
    n_pages <- 100e3
  }

  pb <- create_progress_bar(
    total = n_pages,
    name = "Paginate",
    config = progress
  )
  show_progress <- !is.null(pb)

  out <- vector("list", length = n_pages)
  page <- 0L
  while ((page + 1) <= n_pages) {
    page <- page + 1L

    resp <- req_perform(req)
    parsed <- parse_resp(resp)

    if (page == 1) {
      n_pages <- min(f_n_pages(parsed), n_pages)
    }

    out[[page]] <- parsed$data
    if (show_progress) cli::cli_progress_update(total = n_pages)

    req <- iterate_next_request(req, parsed)
    if (is.null(req)) {
      break
    }
  }
  if (show_progress) cli::cli_progress_done()

  # remove unused tail of `out`
  if (page < length(out)) {
    out <- out[seq2(1, page)]
  }

  vctrs::list_unchop(out)
}

#' Retrieve the next request from an iterative response
#'
#' In most case you should use [req_perform_iteratively()] but you can use
#' this lower-level helper to iterate through the requests and perform them
#' yourself with [req_perform()].
#'
#' @inheritParams req_perform
#' @param parsed The response parsed by the argument `parse_resp` of [req_paginate()].
#' @keywords internal
#' @export
#' @return Generates the next request in an iterative request,
#'   or `NULL` if there are no more pages to return.
#' @examples
#' req_flowers <- request(example_url()) |>
#'   req_url_path("/iris") |>
#'   req_url_query(limit = 40) |>
#'   req_paginate_page_index(
#'     page_index = \(req, page) req |> req_url_query(page_index = page)
#'   )
#' req_flowers$url
#'
#' resp <- req_flowers |> req_perform()
#' next_req <- iterate_next_request(req_flowers, resp)
#' next_req$url
iterate_next_request <- function(req, parsed) {
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
  check_function2(parse_resp, args = "resp")

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
    required_fields = "next_url",
    n_pages = n_pages
  )
}

#' @param set_token A function that applies the new token to the request. It
#'   takes two arguments: a [request] and the new token.
#'
#'   1. `req`: the previous request.
#'   2. `token`: the token for the next page.
#' @rdname req_paginate
#' @export
req_paginate_token <- function(req,
                               set_token,
                               parse_resp,
                               n_pages = NULL) {
  check_function2(set_token, args = c("req", "next_token"))
  check_function2(parse_resp, args = "resp")

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
    required_fields = "next_token",
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

  next_request <- function(req, parsed) {
    new_page <- req$policies$paginate$page + 1L
    req$policies$paginate$page <- new_page
    page_index(req, new_page)
  }

  out <- req_paginate(
    req,
    next_request,
    parse_resp = parse_resp,
    n_pages = n_pages
  )

  out$policies$paginate$page <- 1L
  out
}

check_has_pagination_policy <- function(req, call = caller_env()) {
  if (!req_policy_exists(req, "paginate")) {
    cli::cli_abort(c(
      "{.arg req} doesn't have a pagination policy.",
      i = "You can add pagination via `req_paginate()`."
    ))
  }
}
