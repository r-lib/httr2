#' Perform a multi request
#'
#' Perform a request with a multi policy, e.g. created by [req_paginate()] or
#' [req_chunk()].
#'
#' @inheritParams req_perform
#' @param max_requests The maximum number of requests to perform.
#' @param cancel_on_error Should all pending requests be cancelled when you
#'   hit an error. Set this to `TRUE` to stop all requests as soon as you
#'   hit an error. Responses that were never performed will have class
#'   `httr2_cancelled` in the result.
#' @param progress Display a progress bar? Use `TRUE` to turn on a basic progress
#'   bar, use a string to give it a name, or see [progress_bars] for more details.
#'
#' @return The result of `vec_c()`ing together the `data` fields that were
#'   extracted by the `parse_resp` argument of [req_paginate()].
#'   If `parse_resp` is not specified, it will be a list of the raw responses.
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
#' responses <- req_perform_multi(req_pokemon)
req_perform_multi <- function(req,
                              # paths = NULL,
                              max_requests = NULL,
                              cancel_on_error = FALSE,
                              progress = TRUE,
                              error_call = current_env()) {
  # TODO should also accept a list of requests
  # TODO accept a path pattern?

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
      n_requests <- min(get_n_requests(parsed), n_requests)
    }

    out[[page]] <- parsed$data
    if (show_progress) cli::cli_progress_update(total = n_requests)

    # TODO change name to `req_next()`?
    req <- multi_next_request(req, parsed)
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

req_multi_policy <- function(req,
                             parse_resp,
                             next_request,
                             n_requests,
                             get_n_requests,
                             ...) {
  req_policies(
    req,
    parse_resp = parse_resp,
    multi = list(
      next_request = next_request,
      n_requests = n_requests,
      get_n_requests = get_n_requests,
      ...
    )
  )
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

#' @export
#' @rdname last_response
last_multi_responses <- function() {
  the$last_chunked_responses[seq2(1, the$last_chunk_idx)]
}

#' @export
#' @rdname last_response
last_chunk <- function() {
  the$last_chunks[[the$last_chunk_idx]]
}

#' Create the next request of a multi request
#'
#' Use this function to create the next request for a request that has a
#' multi request policy, e.g. created by [req_paginate()] or [req_chunk()].
#'
#' @param req A [request].
#' @param parsed A parsed response.
#'
#' @return The next request.
#' @export
#'
#' @examples
#' ids <- 1:7
#' chunk_size <- 3
#'
#' apply_chunk <- function(req, chunk) {
#'   chunk <- rlang::set_names(chunk, "id")
#'   req_url_query(req, !!!chunk)
#' }
#'
#' req <- req_chunk(
#'   request("https://example.com"),
#'   ids,
#'   chunk_size = 3,
#'   apply_chunk = apply_chunk
#' )
#'
#' req1 <- multi_next_request(req, parsed = NULL)
#' req1$url
#' req2 <- multi_next_request(req1, parsed = NULL)
#' req2$url
multi_next_request <- function(req, parsed) {
  check_request(req)
  check_has_multi_policy(req)

  next_request <- req$policies$multi$next_request
  next_request(
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
