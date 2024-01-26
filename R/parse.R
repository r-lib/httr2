parse_media <- function(x) {
  # https://datatracker.ietf.org/doc/html/rfc2616#section-3.7
  pieces <- parse_delim(x, ";")
  params <- parse_name_equals_value(pieces[-1], ";")

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
  params <- parse_name_equals_value(parse_delim(pieces[[2]], ","), ";")

  c(list(scheme = pieces[[1]]), params)
}

parse_link <- function(x) {
  links <- parse_delim(x, ",")

  parse_one <- function(x) {
    pieces <- parse_delim(x, ";")

    url <- gsub("^<|>$", "", pieces[[1]])
    params <- parse_name_equals_value(pieces[-1], ";")
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

parse_name_equals_value <- function(x, safe = "&", quote = "\"") {
  if (length(x) == 0) {
    return(NULL)
  }
  # Note: quotes are removed in the parse_delim function
  # re-introduce quotes to create a safe pattern to split on
  safe_pattern <- paste0(quote, safe, quote)
  pieces <- strsplit(sub("=", safe_pattern, x, fixed = T), safe_pattern, fixed = TRUE)
  pieces_matrix <- do.call(rbind, pieces)

  if (ncol(pieces_matrix) == 1) {
    pieces_matrix <- cbind(pieces_matrix, rep("", nrow(pieces_matrix)))
  }

  # If only one piece, assume it's a field name with empty value
  found <- pieces_matrix[, 1] == pieces_matrix[, 2]
  pieces_matrix[found, 2] <- ""
  set_names(as.list(pieces_matrix[, 2]), pieces_matrix[, 1])
}

parse_in_half <- function(x, pattern) {
  loc <- regexpr(pattern, x, perl = TRUE)
  if (length(loc) == 1 && loc == -1) {
    c(x, "")
  } else {
    regmatches(x, loc, invert = TRUE)[[1]]
  }
}

parse_match <- function(x, pattern) {
  m <- regexec(pattern, x, perl = TRUE)
  pieces <- regmatches(x, m)[[1]][-1]

  pieces <- as.list(pieces)
  # replace empty element with null
  pieces[pieces == ""] <- list(NULL)
  return(pieces)
}

empty_to_null <- function(x) {
  if (x == "") NULL else x
}
