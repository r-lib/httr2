req_paginate <- function(req,
                         page_size,
                         results_field,
                         total_field,
                         f_next_page,
                         max_pages = 100L,
                         progress = TRUE,
                         error_call = caller_env()) {
  check_request(req, call = error_call)
  check_param(page_size, allow_null = TRUE, call = error_call)
  check_string(results_field, allow_null = TRUE, call = error_call)
  check_string(total_field, allow_null = TRUE, call = error_call)
  check_function(f_next_page, call = error_call)
  check_number_whole(max_pages, call = error_call)
  check_bool(progress, call = error_call)

  f_data <- if (is.null(results_field)) {
    function(resp, body_parsed) {
      body_parsed
    }
  } else {
    function(resp, body_parsed) {
      purrr::pluck(body_parsed, results_field)
    }
  }

  req <- req_set_param(req, page_size)

  resp1 <- req_perform(req)
  body_parsed <- resp_body_json(resp1)

  n_pages <- calc_n_pages(max_pages, total_field, body_parsed, page_size$value)

  out <- vector("list", length = n_pages)
  out[[1]] <- f_data(resp1, body_parsed)

  cli::cli_progress_bar(
    "Paginate",
    total = n_pages,
    format = "{cli::pb_spin} Page {cli::pb_current}/{cli::pb_total} | ETA: {cli::pb_eta}",
    current = 1L
  )

  for (page in seq2(2, n_pages)) {
    req <- f_next_page(req, resp, body_parsed)
    if (is.null(req)) {
      page <- page - 1L
      break
    }

    resp_page <- req_perform(req)

    body_parsed <- resp_body_json(resp_page)
    out[[page]] <- f_data(resp, body_parsed)

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

req_paginate_next_url <- function(req,
                                  next_url,
                                  results_field = NULL,
                                  page_size = NULL,
                                  total_field = NULL,
                                  max_pages = 100L,
                                  progress = TRUE) {
  check_param(next_url, allow_null_value = TRUE)

  f_next_page <- function(req, resp, body_parsed) {
    next_url <- resp_get_param(resp, body_parsed, next_url)

    if (is.null(next_url)) {
      return(NULL)
    }

    req_url(req, next_url)
  }

  req_paginate(
    req,
    page_size,
    results_field = results_field,
    total_field = total_field,
    f_next_page = f_next_page,
    max_pages = max_pages,
    progress = progress
  )
}

req_paginate_offset <- function(req,
                                offset,
                                results_field = NULL,
                                limit = NULL,
                                total_field = NULL,
                                max_pages = 100L,
                                progress = TRUE) {
  check_param(offset, allow_null_value = TRUE)
  # TODO require `limit`?

  cur_offset <- 0L
  env <- current_env()
  f_next_page <- function(req, resp, body_parsed) {
    cur_offset <- get("cur_offset", envir = env)
    new_offset <- cur_offset + limit$value
    assign("cur_offset", new_offset, envir = env)

    req_set_param(req, offset, new_offset)
  }

  req_paginate(
    req,
    limit,
    results_field = results_field,
    f_next_page = f_next_page,
    total_field = total_field,
    max_pages = max_pages,
    progress = progress
  )
}

req_paginate_next_token <- function(req,
                                    token_field,
                                    next_token_field,
                                    results_field = NULL,
                                    limit = NULL,
                                    total_field = NULL,
                                    max_pages = 100L,
                                    progress = TRUE) {
  check_param(token_field, allow_null_value = TRUE)
  check_param(next_token_field, allow_null_value = TRUE)

  f_next_page <- function(req, resp, body_parsed) {
    next_token <- resp_get_param(resp, body_parsed, next_token_field)

    if (is.null(next_token)) {
      return(NULL)
    }

    req_set_param(req, token_field, next_token)
  }

  req_paginate(
    req,
    limit,
    results_field = results_field,
    total_field = total_field,
    f_next_page = f_next_page,
    max_pages = max_pages,
    progress = progress
  )
}

calc_n_pages <- function(max_pages, total_field, body_parsed, page_size) {
  if (is.null(total_field) || is.null(page_size)) {
    return(max_pages)
  }

  total <- body_parsed[[total_field]]
  if (is.null(total)) {
    return(max_pages)
  }
  n_pages <- ceiling(total / page_size)

  min(n_pages, max_pages)
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

resp_get_param <- function(resp, body_parsed, x) {
  if (is_body_param(x)) {
    purrr::pluck(body_parsed, !!!x$path)
  }
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
