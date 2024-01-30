parse_media <- function(x) {
  # https://datatracker.ietf.org/doc/html/rfc2616#section-3.7
  pieces <- parse_delim(x, ";")
  params <- parse_name_equals_value(pieces[-1])

  if (is_empty(pieces)) {
    list(type = NA_character_)
  } else {
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
  loc <- regexpr("=", x, fixed = TRUE)
  pieces <- regmatches(x, loc, invert = TRUE)

  # If only one piece, assume it's a field name with empty value
  expand <- function(x) if (length(x) == 1) c(x, "") else x
  pieces <- map(pieces, expand)

  val <- trimws(map_chr(pieces, "[[", 2))
  name <- trimws(map_chr(pieces, "[[", 1))

  set_names(as.list(val), name)
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
  m <- regexec(pattern, x, perl = TRUE)
  pieces <- regmatches(x, m)[[1]][-1]
  map(pieces, empty_to_null)
}

empty_to_null <- function(x) {
  if (x == "") NULL else x
}

