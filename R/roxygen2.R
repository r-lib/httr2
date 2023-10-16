rfc <- function(num, sec = NULL) {
  paste0(
    "[",
    if (!is.null(sec)) paste0("Section ", sec, " of "),
    "RFC ", num, "]",
    "(https://datatracker.ietf.org/doc/html/rfc", num,
    if (!is.null(sec)) paste0("#section-", sec),
    ")"
  )
}
