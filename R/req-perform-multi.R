# TODO should also accept a list of requests
# TODO accept a single path?
req_perform_multi <- function(req,
                              # paths = NULL,
                              max_requests = NULL,
                              cancel_on_error = FALSE,
                              progress = TRUE,
                              error_call = current_env()) {
  check_request(req)
  check_has_multi_policy(req)
  check_number_whole(max_requests, allow_infinite = TRUE, allow_null = TRUE, min = 1)
  max_requests <- max_requests %||% Inf

  parse_resp <- req$policies$parse_resp
  n_requests <- min(req$policies$multi$n_requests, max_requests)
  get_n_requests <- req$policies$multi$get_n_requests

  # the implementation below doesn't really support an infinite amount of pages
  # but 100e3 should be plenty
  if (is.infinite(n_requests)) {
    n_requests <- 100e3
  }

  # TODO customise name of progress bar
  pb <- create_progress_bar(
    total = n_requests,
    name = "Paginate",
    config = progress
  )
  show_progress <- !is.null(pb)

  out <- vector("list", length = n_requests)

  page <- 0L
  while ((page + 1) <= n_requests) {
    page <- page + 1L

    resp <- req_perform(req)
    parsed <- parse_resp(resp)

    if (page == 1) {
      n_requests <- min(get_n_requests(resp, parsed), n_requests)
    }

    out[[page]] <- parsed
    if (show_progress) cli::cli_progress_update(total = n_requests)

    # TODO change name to `req_next()`?
    req <- multi_next_request(resp, req, parsed)
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

# req_perform_multi <- function(reqs,
#                               paths = NULL,
#                               cancel_on_error = FALSE,
#                               progress = TRUE,
#                               error_call = current_env()) {
#   n <- length(reqs)
#   if (!is.null(paths)) {
#     if (length(paths) != n) {
#       cli::cli_abort("If supplied, {.arg paths} must be the same length as {.arg req}.")
#     }
#   }
#
#   env <- current_env()
#   out <- rep(list(error_cnd("httr2_cancelled", message = "Request cancelled")), n)
#
#   perform <- error_wrapper(
#     f = req_perform,
#     cancel_on_error = cancel_on_error,
#     error_message = "When requesting chunk {i}.",
#     error_class = "httr2_failure",
#     error_call = error_call
#   )
#   parse_resp <- error_wrapper(
#     f = function(req, resp) {
#       parse_resp <- req$policies$paginate$parse_resp %||% identity
#       parse_resp(resp)
#     },
#     cancel_on_error = cancel_on_error,
#     error_message = "When parsing chunk {i}.",
#     error_class = "httr2_parse_failure",
#     error_call = error_call
#   )
#
#   pb <- create_progress_bar(
#     total = n,
#     name = "Request",
#     config = progress
#   )
#   show_progress <- !is.null(pb)
#
#   tryCatch(
#     {
#       for (i in seq2(1, n)) {
#         req_i <- reqs[[i]]
#         resp_i <- perform(req_i, path = paths[[i]])
#         out[[i]] <- parse_resp(req_i, resp_i)
#         if (show_progress) cli::cli_progress_update()
#       }
#     },
#     interrupt = function(cnd) {
#       # TODO this doesn't seem to work?
#       cnd
#     }
#   )
#
#   if (show_progress) cli::cli_progress_done()
#
#   out
# }

error_wrapper <- function(f,
                          cancel_on_error,
                          error_message,
                          error_class,
                          env = caller_env(),
                          error_call = caller_env()) {
  force(env)

  if (cancel_on_error) {
    function(...) {
      tryCatch(
        f(...),
        error = function(cnd) {
          cli::cli_abort(
            error_message,
            parent = cnd,
            .envir = env,
            call = error_call
          )
        }
      )
    }
  } else {
    function(...) {
      tryCatch(
        f(...),
        error = function(cnd) {
          error_cnd(error_class, message = cnd$msg)
        }
      )
    }
  }
}

create_perform <- function(cancel_on_error,
                           env = caller_env(),
                           error_call = caller_env()) {
  req_perform_cancel <- function(req, path, i) {
    tryCatch(
      req_perform(req, path = path),
      error = function(cnd) {
        cli::cli_abort(
          "When requesting chunk {i}.",
          parent = cnd,
          .envir = env,
          call = error_call
        )
      }
    )
  }

  req_perform_continue <- function(req, path, i) {
    tryCatch(
      req_perform(req, path = path),
      error = function(cnd) {
        error_cnd("httr2_failure", message = cnd$msg)
      }
    )
  }

  if (cancel_on_error) {
    req_perform_cancel
  } else {
    req_perform_continue
  }
}

create_parse_resp <- function(cancel_on_error,
                              env = caller_env(),
                              error_call = caller_env()) {
  resp_parse_cancel <- function(resp, i) {
    parse_resp <- req$policies$paginate$parse_resp %||% identity

    tryCatch(
      parse_resp(resp),
      error = function(cnd) {
        cli::cli_abort(
          "When parsing resp {i}.",
          parent = cnd,
          .envir = env,
          call = error_call
        )
      }
    )
  }

  resp_parse_continue <- function(resp, i) {
    parse_resp <- req$policies$paginate$parse_resp %||% identity

    tryCatch(
      parse_resp(resp),
      error = function(cnd) {
        error_cnd("httr2_parse_failure", message = cnd$msg)
      }
    )
  }

  if (cancel_on_error) {
    resp_parse_cancel
  } else {
    resp_parse_continue
  }
}

multi_next_request <- function(resp, req, parsed) {
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

check_has_multi_policy <- function(req, call = caller_env()) {
  if (!req_policy_exists(req, "multi")) {
    cli::cli_abort(c(
      "{.arg req} doesn't have a multi request policy.",
      i = "You can add pagination via `req_paginate()`.",
      i = "You can create a chunked requests via `req_chunk()`."
    ))
  }
}
