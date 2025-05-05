multi_dots <- function(
  ...,
  .multi = c("error", "comma", "pipe", "explode"),
  .space = c("percent", "form"),
  error_arg = "...",
  error_call = caller_env()
) {
  if (is.function(.multi)) {
    check_function2(.multi, call = error_call, arg = ".multi")
  } else {
    .multi <- arg_match(.multi, error_arg = ".multi", error_call = error_call)
  }
  .space <- arg_match(.space, call = error_call)
  form <- .space == "form"

  dots <- list2(...)
  if (length(dots) == 0) {
    return(list())
  }

  if (!is_named(dots)) {
    cli::cli_abort(
      "All components of {.arg {error_arg}} must be named.",
      call = error_call
    )
  }

  type_ok <- map_lgl(dots, function(x) is_atomic(x) || is.null(x))
  if (any(!type_ok)) {
    cli::cli_abort(
      "All elements of {.arg {error_arg}} must be either an atomic vector or NULL.",
      call = error_call
    )
  }

  n <- lengths(dots)
  if (any(n > 1)) {
    if (is.function(.multi)) {
      dots[n > 1] <- imap(
        dots[n > 1],
        format_query_param,
        multi = TRUE,
        form = form
      )
      dots[n > 1] <- lapply(dots[n > 1], .multi)
      dots[n > 1] <- lapply(dots[n > 1], I)
    } else if (.multi == "comma") {
      dots[n > 1] <- imap(
        dots[n > 1],
        format_query_param,
        multi = TRUE,
        form = form
      )
      dots[n > 1] <- lapply(dots[n > 1], paste0, collapse = ",")
      dots[n > 1] <- lapply(dots[n > 1], I)
    } else if (.multi == "pipe") {
      dots[n > 1] <- imap(
        dots[n > 1],
        format_query_param,
        multi = TRUE,
        form = form
      )
      dots[n > 1] <- lapply(dots[n > 1], paste0, collapse = "|")
      dots[n > 1] <- lapply(dots[n > 1], I)
    } else if (.multi == "explode") {
      dots <- explode(dots)
      n <- lengths(dots)
    } else if (.multi == "error") {
      cli::cli_abort(
        c(
          "All vector elements of {.arg {error_arg}} must be length 1.",
          i = "Use {.arg .multi} to choose a strategy for handling vectors."
        ),
        call = error_call
      )
    }
  }

  # Format other params
  dots[n == 1] <- imap(
    dots[n == 1],
    format_query_param,
    form = form,
    error_call = error_call
  )
  dots[n == 1] <- lapply(dots[n == 1], I)

  dots
}

explode <- function(x) {
  expanded <- map(x, function(x) {
    if (is.null(x)) {
      list(NULL)
    } else {
      map(seq_along(x), function(i) x[i])
    }
  })
  stats::setNames(
    unlist(expanded, recursive = FALSE, use.names = FALSE),
    rep(names(x), lengths(expanded))
  )
}
