#' Perform a multi request
#'
#' Perform a request with a multi policy, e.g. created by [req_paginate()] or
#' [req_chunk()].
#'
#' @inheritParams req_perform
#' @param path Optionally, path to save the body of the responses. The path
#'   should contain the string `"%i"` which is replaced by the index of the
#'   current request.
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
                              path = NULL,
                              max_requests = NULL,
                              cancel_on_error = FALSE,
                              progress = TRUE,
                              error_call = current_env()) {
  check_request(req)
  check_has_multi_policy(req)
  check_string(path, allow_null = TRUE)
  if (!is.null(path) && !grepl("%i", path)) {
    cli::cli_abort("{.arg path} must contain the string {.val %i}.")
  }
  check_number_whole(max_requests, allow_infinite = TRUE, allow_null = TRUE, min = 1)
  max_requests <- max_requests %||% Inf

  n_requests <- min(req$policies$multi$n_requests, max_requests)
  get_n_requests <- req$policies$multi$get_n_requests

  pb <- create_progress_bar(
    total = n_requests,
    name = req$policies$multi$type,
    config = progress
  )
  show_progress <- !is.null(pb)

  perform <- error_wrapper(
    f = req_perform,
    cancel_on_error = cancel_on_error,
    error_message = "When performing request {i}.",
    error_class = "httr2_failure",
    error_call = error_call
  )

  parse_resp <- error_wrapper(
    f = function(resp) {
      parse_resp <- req$policies$parse_resp
      parse_resp(resp)
    },
    cancel_on_error = cancel_on_error,
    error_message = "When parsing response {i}.",
    error_class = "httr2_parse_failure",
    error_call = error_call
  )

  # the implementation below doesn't really support an infinite amount of pages
  # but 100e3 should be plenty
  # `pb_total` is needed to support the case when `n_requests` is infinite
  pb_total <- n_requests
  if (is.infinite(n_requests)) {
    n_requests <- min(n_requests, 100e3)
  }
  out <- rep(list(cancelled_response()), n_requests)

  req <- req$policies$multi$init(req)
  i <- 0L
  path_i <- NULL
  while ((i + 1) <= n_requests) {
    i <- i + 1L
    if (!is.null(path)) {
      path_i <- gsub("%i", i, path, fixed = TRUE)
    }

    resp <- perform(req, path = path_i)
    parsed <- parse_resp(resp)

    if (i == 1) {
      n_requests_new <- get_n_requests(parsed)
      n_requests <- min(n_requests_new, n_requests)

      pb_total <- min(n_requests_new, pb_total)
      if (!is.infinite(pb_total)) {
        cli::cli_progress_update(inc = 0, total = pb_total)
      }
    }

    out[[i]] <- parsed$data
    if (show_progress) {
      cli::cli_progress_update()
    }

    req <- req_next_multi(req, parsed)
    if (is.null(req)) {
      break
    }
  }
  if (show_progress) cli::cli_progress_done()

  # remove unused tail of `out`
  if (i < length(out)) {
    out <- out[seq2(1, i)]
  }

  vctrs::list_unchop(out)
}

req_multi_policy <- function(req,
                             parse_resp,
                             type,
                             next_request,
                             n_requests,
                             get_n_requests,
                             ...) {
  req_policies(
    req,
    parse_resp = parse_resp,
    multi = list(
      type = type,
      next_request = next_request,
      n_requests = n_requests,
      get_n_requests = get_n_requests,
      ...
    )
  )
}

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
#' req1 <- req_next_multi(req, parsed = NULL)
#' req1$url
#' req2 <- req_next_multi(req1, parsed = NULL)
#' req2$url
req_next_multi <- function(req, parsed) {
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
    ), call = call)
  }
}
