
bullets_with_header <- function(header, x) {
  if (length(x) == 0) {
    return()
  }

  cli::cli_text("{.emph {header}}")
  cli::cli_li("{.field {names(x)}}: {x}")
}
