bullets_with_header <- function(header, x) {
  if (length(x) == 0) {
    return()
  }

  cli::cli_text("{.strong {header}}")
  cli::cli_li("{.field {names(x)}}: {x}")
}
