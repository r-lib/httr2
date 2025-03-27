#' @export
#' @rdname resp_stream_raw
#' @order 2
resp_stream_aws <- function(resp, max_size = Inf) {
  event_bytes <- resp_boundary_pushback(
    resp = resp,
    max_size = max_size,
    boundary_func = find_aws_event_boundary,
    include_trailer = FALSE
  )

  if (is.null(event_bytes)) {
    return()
  }

  event <- parse_aws_event(event_bytes)
  if (resp_stream_show_body(resp)) {
    # Emit header
    for (key in names(event$headers)) {
      log_stream(cli::style_bold(key), ": ", event$headers[[key]])
    }
    # Emit body
    log_stream(jsonlite::toJSON(event$body, auto_unbox = TRUE, pretty = TRUE))
    cli::cat_line()
  }
  event
}

find_aws_event_boundary <- function(buffer) {
  # No valid AWS event message is less than 16 bytes
  if (length(buffer) < 16) {
    return(NULL)
  }

  # Read first 4 bytes as a big endian number
  event_size <- parse_int(buffer[1:4])
  if (event_size > length(buffer)) {
    return(NULL)
  }

  event_size + 1
}

# Implementation from https://github.com/lifion/lifion-aws-event-stream/blob/develop/lib/index.js
# This is technically buggy because it takes the header_length as a lower bound
# but this shouldn't cause problems in practive
parse_aws_event <- function(bytes) {
  i <- 1
  read_bytes <- function(n) {
    if (n == 0) {
      return(raw())
    }
    out <- bytes[i:(i + n - 1)]
    i <<- i + n
    out
  }

  # prelude
  total_length <- parse_int(read_bytes(4))
  if (total_length != length(bytes)) {
    cli::cli_abort(
      "AWS event metadata doesn't match supplied bytes",
      .internal = TRUE
    )
  }

  header_length <- parse_int(read_bytes(4))
  prelude_crc <- read_bytes(4)
  # TODO: use this value to check prelude lengths

  # headers
  headers <- list()
  while (i <= 12 + header_length) {
    name_length <- as.integer(read_bytes(1))
    name <- rawToChar(read_bytes(name_length))
    type <- as.integer(read_bytes(1))

    delayedAssign("length", parse_int(read_bytes(2)))
    value <- switch(
      type_enum(type),
      "TRUE" = TRUE,
      "FALSE" = FALSE,
      BYTE = parse_int(read_bytes(1)),
      SHORT = parse_int(read_bytes(2)),
      INTEGER = parse_int(read_bytes(4)),
      LONG = parse_int64(read_bytes(8)),
      BYTE_ARRAY = read_bytes(length),
      CHARACTER = rawToChar(read_bytes(length)),
      TIMESTAMP = parse_int64(read_bytes(8)),
      UUID = raw_to_hex(read_bytes(16)),
    )
    headers[[name]] <- value
  }

  # body
  body_raw <- read_bytes(total_length - i - 4 + 1)
  crc_raw <- read_bytes(4)
  # TODO: use this value to check data

  body <- rawToChar(body_raw)
  if (identical(headers$`:content-type`, "application/json")) {
    body <- jsonlite::parse_json(body)
  }

  list(headers = headers, body = body)
}


# Helpers ----------------------------------------------------------------

parse_int <- function(x) {
  sum(as.integer(x) * 256^rev(seq_along(x) - 1))
}

parse_int64 <- function(x) {
  y <- readBin(x, "double", n = 1, size = length(x), endian = "big")
  class(y) <- "integer64"
  y
}

type_enum <- function(value) {
  if (value < 0 || value > 10) {
    cli::cli_abort("Unsupported type {value}.", .internal = TRUE)
  }

  switch(
    value + 1,
    "TRUE",
    "FALSE",
    "BYTE",
    "SHORT",
    "INTEGER",
    "LONG",
    "BYTE_ARRAY",
    "CHARACTER",
    "TIMESTAMP",
    "UUID"
  )
}

hex_to_raw <- function(x) {
  x <- gsub("(\\s|\n)+", "", x)

  pairs <- substring(x, seq(1, nchar(x), by = 2), seq(2, nchar(x), by = 2))
  as.raw(strtoi(pairs, 16L))
}

raw_to_hex <- function(x) {
  paste(as.character(x), collapse = "")
}
