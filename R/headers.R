as_headers <- function(
  x,
  redact = character(),
  lifespan,
  error_call = caller_env()
) {
  if (is.list(x)) {
    new_headers(
      x,
      redact = redact,
      lifespan = lifespan,
      error_call = error_call
    )
  } else if (is.character(x) || is.raw(x)) {
    parsed <- curl::parse_headers(x)
    valid <- parsed[grepl(":", parsed, fixed = TRUE)]
    halves <- parse_in_half(valid, ":")

    headers <- set_names(trimws(halves$right), halves$left)
    new_headers(
      as.list(headers),
      redact = redact,
      lifespan = lifespan,
      error_call = error_call
    )
  } else {
    cli::cli_abort(
      "{.arg headers} must be a list, character vector, or raw.",
      call = error_call
    )
  }
}

new_headers <- function(
  x,
  redact = character(),
  lifespan,
  error_call = caller_env()
) {
  if (!is_list(x)) {
    cli::cli_abort("{.arg x} must be a list.", call = error_call)
  }
  if (length(x) > 0 && !is_named(x)) {
    cli::cli_abort("All elements of {.arg x} must be named.", call = error_call)
  }
  for (i in seq_along(x)) {
    if (!is.atomic(x[[i]]) && !is_weakref(x[[i]])) {
      cli::cli_abort(
        c(
          "Each element of {.arg x} must be an atomic vector or a weakref.",
          i = "{.arg x[[{i}]]} is {obj_type_friendly(x[[i]])}."
        ),
        call = error_call
      )
    }
  }

  needs_redact <- !is_redacted(x) & (tolower(names(x)) %in% tolower(redact))
  x[needs_redact] <- lapply(x[needs_redact], \(x) new_weakref(lifespan, x))

  structure(x, class = "httr2_headers")
}

#' @export
print.httr2_headers <- function(x, ..., redact = TRUE) {
  cli::cat_line(cli::format_inline("{.cls {class(x)}}"))
  show_headers(x, redact = redact)
  invisible(x)
}

show_headers <- function(x, redact = TRUE) {
  if (length(x) > 0) {
    vals <- lapply(headers_flatten(x, redact), format)
    cli::cat_line(cli::style_bold(names(x)), ": ", vals)
  }
}

#' @export
str.httr2_headers <- function(object, ..., no.list = FALSE) {
  object <- unclass(headers_flatten(object))
  cat(" <httr2_headers>\n")
  utils::str(object, ..., no.list = TRUE)
}

#' @export
`[.httr2_headers` <- function(x, i, ...) {
  if (is.character(i)) {
    i <- match(tolower(i), tolower(names(x)))
  }

  new_headers(NextMethod())
}

#' @export
`[[.httr2_headers` <- function(x, i) {
  if (is.character(i)) {
    i <- match(tolower(i), tolower(names(x)))
  }
  NextMethod()
}

#' @export
"$.httr2_headers" <- function(x, name) {
  i <- match(tolower(name), tolower(names(x)))
  x[[i]]
}

is_redacted <- function(x) {
  map_lgl(x, is_weakref)
}
which_redacted <- function(x) {
  names(x)[is_redacted(x)]
}

# Flatten headers object into a list suitable either for display (if redacted)
# or passing to curl (if not redacted).
headers_flatten <- function(x, redact = TRUE) {
  is_redacted <- is_redacted(x)

  out <- vector("list", length(x))
  names(out) <- names(x)

  # https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.2
  out[!is_redacted] <- lapply(x[!is_redacted], paste, collapse = ",")

  if (redact) {
    out[is_redacted] <- list(redacted_sentinel())
  } else {
    out[is_redacted] <- lapply(x[is_redacted], wref_value)
    # also need to ensure redacted values are simple strings
    out[is_redacted] <- lapply(out[is_redacted], function(x) {
      if (!is.null(x)) paste(x, collapse = ",")
    })
    # need to strip serialized weakrefs that now yield NULL
    out <- compact(out)
  }

  out
}
