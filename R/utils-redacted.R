redacted_sentinel <- function() {
  structure(list(NULL), class = "httr2_redacted_sentinel")
}
#' @export
print.httr2_redacted_sentinel <- function(x, ...) {
  cat(format(x), "\n", sep = "")
  invisible(x)
}
#' @export
format.httr2_redacted_sentinel <- function(x, ...) {
  unclass(cli::col_grey("<REDACTED>"))
}
#' @export
str.httr2_redacted_sentinel <- function(object, ..., nest.lev = 0) {
  str_leading_space(nest.lev)
  cat(cli::col_grey("<REDACTED>"), "\n", sep = "")
}

list_redact <- function(x, names) {
  x[names(x) %in% names] <- list(redacted_sentinel())
  x
}

is_redacted_sentinel <- function(x) {
  inherits(x, "httr2_redacted_sentinel")
}

.str_legacy <- NULL

str_leading_space <- function(nest.lev) {
  # R 4.7.0 and later supply the separator when calling nested str() methods
  if (nest.lev > 0 && .str_legacy) {
    cat(" ")
  }
}
