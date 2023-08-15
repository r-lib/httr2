req_paginate <- function(req,
                         limit,
                         results_field,
                         f_n_pages,
                         f_next_page,
                         max_pages = 100L,
                         progress = TRUE) {
  check_request(req)
  check_param(limit)
  check_string(results_field, allow_null = TRUE)
  check_function(f_n_pages)
  check_function(f_next_page)
  check_number_whole(max_pages)
  check_bool(progress)

  f_data <- if (is.null(results_field)) {
    function(resp, body_parsed) {
      body_parsed
    }
  } else {
    function(resp, body_parsed) {
      purrr::pluck(body_parsed, results_field)
    }
  }

  if (is_query_param(limit)) {
    req <- req_url_query(req, "{limit$name}" := limit$value)
  } else if (is_body_param(limit)) {
    data <- req$body$data %||% set_names(list())
    data <- purrr::assign_in(data, limit$path, limit$value)
    req <- req_body_json(req, data)
  }

  resp1 <- req_perform(req)
  body_parsed <- resp_body_json(resp1)

  n_pages <- min(f_n_pages(resp1, body_parsed, limit$value), max_pages)

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
                                  next_field,
                                  results_field = NULL,
                                  limit = NULL,
                                  total_field = NULL,
                                  max_pages = 100L,
                                  progress = TRUE) {
  check_string(next_field)
  check_param(limit, allow_null = TRUE)
  check_string(total_field, allow_null = TRUE)
  check_number_whole(max_pages)
  check_bool(progress)

  f_n_pages <- if (is.null(total_field)) {
    function(resp, body_parsed, limit_value) {
      NULL
    }
  } else {
    function(resp, body_parsed, limit_value) {
      total <- body_parsed[[total_field]]
      if (is.null(total)) {
        return(NULL)
      }

      ceiling(total / limit_value)
    }
  }

  f_next_page <- function(req, resp, body_parsed) {
    next_url <- body_parsed[[next_field]]

    if (is.null(next_url)) {
      return(NULL)
    }

    req_url(req, next_url)
  }

  req_paginate(
    req,
    limit,
    results_field = results_field,
    f_n_pages = f_n_pages,
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
  check_param(limit, allow_null = TRUE)
  check_string(total_field, allow_null = TRUE)
  check_number_whole(max_pages)
  check_bool(progress)

  f_n_pages <- if (is.null(total_field)) {
    function(resp, body_parsed, limit_value) {
      NULL
    }
  } else {
    function(resp, body_parsed, limit_value) {
      total <- body_parsed[[total_field]]
      if (is.null(total)) {
        return(NULL)
      }

      ceiling(total / limit_value)
    }
  }

  cur_offset <- 0L
  env <- current_env()
  if (is_query_param(offset)) {
    f_next_page <- function(req, resp, body_parsed) {
      cur_offset <- get("cur_offset", envir = env)
      cur_offset <- cur_offset + offset$value
      assign("cur_offset", cur_offset, envir = env)
      req_url_query(req, "{offset$name}" := cur_offset)
    }
  } else if (is_body_param(offset)) {
    # TODO?
  }

  req_paginate(
    req,
    limit,
    results_field = results_field,
    f_n_pages = f_n_pages,
    f_next_page = f_next_page,
    max_pages = max_pages,
    progress = progress
  )
}

req_paginate_next_token <- function(req,
                                    limit = NULL,
                                    token_field,
                                    next_token_field = "nextToken",
                                    total_field = NULL,
                                    results_field = "results",
                                    max_pages = 100L,
                                    progress = TRUE) {
  check_string(next_token_field)
  check_string(total_field, allow_null = TRUE)
  check_number_whole(max_pages)
  check_bool(progress)

  f_n_pages <- if (is.null(total_field)) {
    function(resp, body_parsed, limit_value) {
      NULL
    }
  } else {
    function(resp, body_parsed, limit_value) {
      total <- body_parsed[[total_field]]
      if (is.null(total)) {
        return(NULL)
      }

      ceiling(total / limit_value)
    }
  }

  f_next_page <- function(req, resp, body_parsed) {
    next_token <- body_parsed[[next_token_field]]

    if (is.null(next_token)) {
      return(NULL)
    }

    if (is_body_param(token_field)) {
      req$body$data[[token_field]] <- jsonlite::unbox(next_token)
    } else if (is_query_param(token_field)) {
      req_url_query(req, "{token_field$name}" := next_token)
    }
    req
  }

  req_paginate(
    req,
    limit,
    results_field = results_field,
    f_n_pages = f_n_pages,
    f_next_page = f_next_page,
    max_pages = max_pages,
    progress = progress
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
