as_headers <- function(x, redact = character(), error_call = caller_env()) {
  if (is.character(x) || is.raw(x)) {
    parsed <- curl::parse_headers(x)
    valid <- parsed[grepl(":", parsed, fixed = TRUE)]
    halves <- parse_in_half(valid, ":")

    headers <- set_names(trimws(halves$right), halves$left)
    new_headers(as.list(headers), redact = redact, error_call = error_call)
  } else if (is.list(x)) {
    new_headers(x, redact = redact, error_call = error_call)
  } else {
    cli::cli_abort(
      "{.arg headers} must be a list, character vector, or raw.",
      call = error_call
    )
  }
}

new_headers <- function(x, redact = character(), error_call = caller_env()) {
  if (!is_list(x)) {
    cli::cli_abort("{.arg x} must be a list.", call = error_call)
  }
  if (length(x) > 0 && !is_named(x)) {
    cli::cli_abort("All elements of {.arg x} must be named.", call = error_call)
  }

  structure(x, redact = redact, class = "httr2_headers")
}

#' @export
print.httr2_headers <- function(x, ..., redact = TRUE) {
  cli::cat_line(cli::format_inline("{.cls {class(x)}}"))
  show_headers(x, redact = redact)
  invisible(x)
}

show_headers <- function(x, redact = TRUE) {
  if (length(x) > 0) {
    vals <- lapply(headers_redact(x, redact), format)
    cli::cat_line(cli::style_bold(names(x)), ": ", vals)
  }
}

#' @export
str.httr2_headers <- function(x, ...) {
  x <- unclass(headers_redact(x))
  utils::str(x, ...)
}

headers_redact <- function(x, redact = TRUE) {
  if (!redact) {
    x
  } else {
    to_redact <- attr(x, "redact")
    attr(x, "redact") <- NULL

    list_redact(x, to_redact, case_sensitive = FALSE)
  }
}

headers_flatten <- function(x) {
  n <- lengths(x)
  x[n > 1] <- lapply(x[n > 1], paste, collapse = ",")
  x
}

list_redact <- function(x, names, sentinel = redacted(), case_sensitive = TRUE) {
  x <- as.list(x)
  if (case_sensitive) {
    i <- match(names, names(x))
  } else {
    i <- match(tolower(names), tolower(names(x)))
  }
  x[i] <- list(redacted())
  x
}

redacted <- function() {
  structure(list(NULL), class = "httr2_redacted")
}

#' @export
format.httr2_redacted <- function(x, ...) {
  cli::col_grey("<REDACTED>")
}
#' @export
str.httr2_redacted <- function(x, ...) {
  cat(" ", cli::col_grey("<REDACTED>"), "\n", sep = "")
}

is_redacted <- function(x) {
  inherits(x, "httr2_redacted")
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
