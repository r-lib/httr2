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
str.httr2_redacted_sentinel <- function(object, ...) {
  cat(" ", cli::col_grey("<REDACTED>"), "\n", sep = "")
}

list_redact <- function(x, names) {
  x[names(x) %in% names] <- list(redacted_sentinel())
  x
}

is_redacted_sentinel <- function(x) {
  inherits(x, "httr2_redacted_sentinel")
}
