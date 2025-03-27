rfc <- function(num, sec = NULL) {
  paste_c(
    c(
      "[",
      if (!is.null(sec)) paste0("Section ", sec, " of "),
      "RFC ",
      num,
      "]"
    ),
    c(
      "(https://datatracker.ietf.org/doc/html/rfc",
      num,
      if (!is.null(sec)) paste0("#section-", sec),
      ")"
    )
  )
}
