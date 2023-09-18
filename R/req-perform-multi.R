req_perform_multi <- function(requests,
                              progress = TRUE,
                              cancel_on_error = FALSE,
                              error_call = current_env()) {
  the$multi$requests <- requests
  n <- length(requests)

  resp_cancelled <- error_cnd("httr2_cancelled", message = "Request cancelled")
  the$multi$responses <- rep(list(resp_cancelled), n)
  the$multi$parsed <- vector("list", n)
  # TODO where to get `parse_resp()` from?
  parse_resp <- identity

  # TODO allow customising name
  pb <- create_progress_bar(total = n, name = "Request chunks", progress)
  show_progress <- !is.null(pb)
  env <- current_env()

  for (i in seq2(1, n)) {
    req_i <- requests[[i]]
    the$multi$last_request[[i]] <- req_i

    if (cancel_on_error) {
      resp_i <- try_fetch(
        req_perform(req_i),
        error = function(cnd) {
          cli::cli_abort(
            "When performing request {i}.",
            parent = cnd,
            .envir = env,
            call = error_call
          )
        }
      )
    } else {
      resp_i <- try_fetch(
        req_perform(req_i),
        error = identity
      )
    }
    the$multi$responses[[i]] <- resp_i

    # if (cancel_on_error) {
      # browser()
      try_fetch(
        parsed <- parse_resp(resp_i),
        error = function(cnd) {
          cli::cli_abort(
            "When parsing response {i}.",
            parent = cnd,
            .envir = env,
            call = error_call
          )
        }
      )
    # }
    # TODO how to handle parsing failures?
    # httr2_parse_error

    the$multi$parsed[[i]] <- parsed
    the$multi$last_i <- i

    if (show_progress) cli::cli_progress_update()
  }
  if (show_progress) cli::cli_progress_done()

  the$multi$responses
}

resp_success <- function(responses) {
  vapply(responses, inherits, "error", FUN.VALUE = logical(1))
}

resp_any_fail <- function(responses) {
  any(!resp_success)
}

resp_all_success <- function(responses) {
  all(resp_success)
}
