
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
#' @param total A character that specifies the path where in the body the field
#'   with the total number of elements is stored.
#' @param next_url A character that specifies the path where in the body the field
#'   with the next url of the next page is stored.
#' @param offset A parameter object that specifies how the offset is added to
#'   the request.
#' @param token_field A parameter object that specifies how the next token is
#'   added to the request.
#' @param next_token_field A character that specifies the path where in the body
#'   the field with the token of the next page is stored.
#'
#' @return A modified HTTP [request].
#' @export
#'
#' @examples
#' request("https://pokeapi.co/api/v2/pokemon") %>%
#'   req_paginate_next_url(
#'     "next",
#'     page_size = in_query("limit", 150L),
#'     total = "count"
#'   )
req_paginate <- function(req,
                         next_request,
                         page_size = NULL,
                         total = NULL) {
  check_request(req)
  check_function(next_request)
  check_param(page_size, allow_null = TRUE)
  check_character(total)

  req <- req_set_param(req, page_size)

  req_policies(
    req,
    next_request = next_request,
    page_size = page_size$value,
    total = total
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
#'   req_paginate_next_url(
#'     "next",
#'     page_size = in_query("limit", 150L),
#'     total = "count"
#'   )
#'
#' responses <- paginate_perform(req_pokemon)
paginate_perform <- function(req,
                             max_pages = 20L,
                             progress = TRUE) {
  check_request(req)
  check_bool(progress)

  resp <- req_perform(req)

  n_pages <- paginate_n_pages(resp, req, max_pages = max_pages)

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

  req_policy_call(
    req,
    "next_request",
    args = list(resp = resp, req = req),
    default = NULL
  )
}

#' @rdname paginate_perform
paginate_n_pages <- function(resp, req, max_pages) {
  check_response(resp)
  check_request(req)

  page_size <- req$policies$page_size
  total <- req$policies$total

  if (is.null(total) || is.null(page_size)) {
    return(max_pages)
  }

  body_parsed <- resp_body_json(resp)
  total <- purrr::pluck(body_parsed, total)
  if (is.null(total)) {
    return(max_pages)
  }
  n_pages <- ceiling(total / page_size)

  min(n_pages, max_pages)
}

#' @rdname req_paginate
#' @export
req_paginate_next_url <- function(req,
                                  next_url,
                                  ...,
                                  page_size = NULL,
                                  total = NULL) {
  check_character(next_url)

  next_request <- function(req, resp) {
    body_parsed <- resp_body_json(resp)
    next_url <- purrr::pluck(body_parsed, next_url)

    if (is.null(next_url)) {
      return(NULL)
    }

    req_url(req, next_url)
  }

  req_paginate(
    req,
    next_request,
    page_size = page_size,
    total = total
  )
}

#' @rdname req_paginate
#' @export
req_paginate_offset <- function(req,
                                offset,
                                page_size,
                                total = NULL) {
  check_param(offset, allow_null_value = TRUE)
  check_param(page_size)

  cur_offset <- 0L
  env <- current_env()
  next_request <- function(resp, req) {
    cur_offset <- get("cur_offset", envir = env)
    new_offset <- cur_offset + page_size$value
    assign("cur_offset", new_offset, envir = env)

    req_set_param(req, offset, new_offset)
  }

  req_paginate(
    req,
    next_request,
    page_size = page_size,
    total = total
  )
}

#' @rdname req_paginate
#' @export
req_paginate_next_token <- function(req,
                                    token_field,
                                    next_token_field,
                                    page_size = NULL,
                                    total = NULL) {
  check_param(token_field, allow_null_value = TRUE)
  check_character(next_token_field)

  next_request <- function(req, resp) {
    body_parsed <- resp_body_json(resp)
    next_token <- purrr::pluck(body_parsed, next_token_field)

    if (is.null(next_token)) {
      return(NULL)
    }

    req_set_param(req, token_field, next_token)
  }

  req_paginate(
    req,
    next_request,
    page_size = page_size,
    total = total
  )
}

in_query <- function(name,
                     value = NULL,
                     error_call = caller_env()) {
  check_string(name, call = error_call)
  out <- list(value = value, name = name)
  class(out) <- c("httr2_query_param", "httr2_param")
  out
}

in_header <- function(name,
                      value = NULL,
                      error_call = caller_env()) {
  check_string(name, call = error_call)
  out <- list(value = value, name = name)
  class(out) <- c("httr2_header_param", "httr2_param")
  out
}

in_body <- function(path,
                    value = NULL,
                    error_call = caller_env()) {
  # TODO check path
  out <- list(value = value, path = path)
  class(out) <- c("httr2_body_param", "httr2_param")
  out
}

check_param <- function(x,
                        ...,
                        allow_null = FALSE,
                        allow_null_value = FALSE,
                        arg = caller_arg(x),
                        call = caller_env()) {
  if (!missing(x)) {
    if (is_param(x)) {
      if (is.null(x$value) && !allow_null_value) {
        abort("{.arg value} must not be `NULL`.", call = call)
      }
      return(invisible(NULL))
    }
    if (allow_null && is_null(x)) {
      return(invisible(NULL))
    }
  }

  stop_input_type(
    x,
    "an httr2 parameter object",
    allow_null = FALSE,
    arg = arg,
    call = call
  )
}

is_param <- function(x) {
  inherits(x, "httr2_param")
}

is_query_param <- function(x) {
  inherits(x, "httr2_query_param")
}

is_body_param <- function(x) {
  inherits(x, "httr2_body_param")
}

is_header_param <- function(x) {
  inherits(x, "httr2_header_param")
}

req_set_param <- function(req, x, value = NULL) {
  value <- value %||% x$value

  if (is_query_param(x)) {
    req_url_query(req, "{x$name}" := value)
  } else if (is_body_param(x)) {
    data <- req$body$data %||% set_names(list())
    data <- purrr::assign_in(data, x$path, value)
    req_body_json(req, data)
  }
}
