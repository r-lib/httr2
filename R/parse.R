parse_media <- function(x) {
  # https://datatracker.ietf.org/doc/html/rfc2616#section-3.7
  pieces <- parse_delim(x, ";")

  if (is_empty(pieces)) {
    list(type = NA_character_)
  } else {
    params <- parse_name_equals_value(pieces[-1])
    c(list(type = pieces[[1]]), params)
  }
}

parse_www_authenticate <- function(x) {
  # Seems little general support for multiple schemes in one header
  # https://stackoverflow.com/questions/10239970

  pieces <- parse_in_half(x, " ")
  params <- parse_name_equals_value(parse_delim(pieces$right, ","))

  c(list(scheme = pieces$left), params)
}

parse_link <- function(x) {
  links <- parse_delim(x, ",")

  parse_one <- function(x) {
    pieces <- parse_delim(x, ";")

    url <- gsub("^<|>$", "", pieces[[1]])
    params <- parse_name_equals_value(pieces[-1])
    c(list(url = url), params)
  }

  lapply(links, parse_one)
}

# Helpers -----------------------------------------------------------------

parse_delim <- function(x, delim, quote = "\"", ...) {
  # Use scan to deal with quoted strings. It loses the quotes, but it's
  # ok because the field name can't be a quoted string so there's no ambiguity
  # about who the = belongs to.
  scan(
    text = x,
    what = character(),
    sep = delim,
    quote = quote,
    quiet = TRUE,
    strip.white = TRUE,
    ...
  )
}

parse_name_equals_value <- function(x) {
  halves <- parse_in_half(x, "=")
  set_names(halves$right, halves$left)
}

parse_in_half <- function(x, char = "=") {
  match <- regexpr(char, x, fixed = TRUE)
  match_loc <- as.vector(match)
  match_len <- attr(match, "match.length")

  left_start <- 1
  left_end <- match_loc - 1
  right_start <- match_loc + match_len
  right_end <- nchar(x)

  no_match <- match_loc == -1
  left_end[no_match] <- right_end[no_match]
  right_start[no_match] <- 0
  right_end[no_match] <- 0

  list(
    left = substr(x, left_start, left_end),
    right = substr(x, right_start, right_end)
  )
}

parse_match <- function(x, pattern) {
  match_loc <- regexpr(pattern, x, perl = TRUE)
  cap_start <- attr(match_loc,"capture.start")
  cap_len <- attr(match_loc, "capture.length")
  cap_end <- (cap_start + cap_len - 1)
  cap_end[cap_end == -1] <- 0
  pieces <- as.list(substring(x, cap_start, cap_end))
  pieces[pieces == ""] <- list(NULL)
  return(pieces)
}
