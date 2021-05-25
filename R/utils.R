bullets_with_header <- function(header, x) {
  if (length(x) == 0) {
    return()
  }

  cli::cli_text("{.strong {header}}")
  cli::cli_li(paste0("{.field ", names(x), "}: ", x))
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

