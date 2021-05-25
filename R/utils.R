bullets_with_header <- function(header, x) {
  if (length(x) == 0) {
    return()
  }

  cli::cli_text("{.strong {header}}")

  as_simple <- function(x) {
    if (is.atomic(x) && length(x) == 1) {
      if (is.character(x)) {
        paste0("'", x, "'")
      } else {
        format(x)
      }
    } else {
      friendly_type_of(x)
    }
  }
  vals <- map_chr(x, as_simple)

  cli::cli_li(paste0("{.field ", names(x), "}: ", vals))
}

modify_list <- function(x, ...) {
  dots <- list2(...)
  if (length(dots) == 0) return(x)

  if (!is_named(dots)) {
    abort("All components of ... must be named")
  }
  x[names(dots)] <- dots
  x
}

