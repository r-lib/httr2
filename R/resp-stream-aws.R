#' @export
#' @rdname resp_stream_raw
#' @order 4
resp_stream_aws <- function(resp, max_size = Inf) {
  splitter <- init_streaming_response(resp, AwsSplitter)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)

  blocks <- stream_pull(resp, 1, splitter, max_size)
  if (length(blocks) == 0L) {
    return()
  }
  event_bytes <- blocks[[1L]]

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

AwsSplitter <- R6::R6Class(
  "AwsSplitter",
  inherit = StreamSplitter,
  public = list(
    name = "resp_stream_aws()",
    find_boundaries = function(buffer) find_aws_event_boundaries(buffer)
  )
)

# Find every complete AWS event in a buffer by walking the 4-byte big-endian
# length prefix at the start of each event. Returns a vector of split points
# (the position one past the end of each complete event).
find_aws_event_boundaries <- function(buffer) {
  n <- length(buffer)
  splits <- double()
  pos <- 1
  repeat {
    # No valid AWS event message is less than 16 bytes.
    if (n - pos + 1L < 16L) {
      break
    }
    # Read the first 4 bytes of the event as a big endian number.
    event_size <- parse_int(buffer[pos:(pos + 3L)])
    if (event_size > n - pos + 1L) {
      break
    }
    pos <- pos + event_size
    splits[[length(splits) + 1L]] <- pos
  }
  splits
}

# Parse a single AWS event-stream message (content type
# application/vnd.amazon.eventstream). The binary format is documented by AWS:
# * https://smithy.io/2.0/aws/amazon-eventstream.html (canonical protocol spec)
# * https://docs.aws.amazon.com/lexv2/latest/dg/event-stream-encoding.html
# Reference implementation: https://github.com/awslabs/aws-eventstream-java
#
# Key details: all integers are big-endian; the prelude (total + header lengths)
# and the whole message each end in a GZIP/zlib CRC32; header value types
# byte/short/integer/long are signed; timestamp is an int64 of epoch millis.
#
# We treat header_length as a lower bound rather than an exact count; this is
# lenient but harmless and matches some reference implementations.
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
      BYTE = parse_int(read_bytes(1), signed = TRUE),
      SHORT = parse_int(read_bytes(2), signed = TRUE),
      INTEGER = parse_int(read_bytes(4), signed = TRUE),
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

parse_int <- function(x, signed = FALSE) {
  v <- sum(as.integer(x) * 256^rev(seq_along(x) - 1))
  if (signed && v >= 2^(8 * length(x) - 1)) {
    # Interpret as two's complement.
    v <- v - 2^(8 * length(x))
  }
  v
}

parse_int64 <- function(x) {
  y <- readBin(x, "double", n = 1, size = length(x), endian = "big")
  class(y) <- "integer64"
  y
}

type_enum <- function(value) {
  if (value < 0 || value > 9) {
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

raw_to_hex <- function(x) {
  paste(as.character(x), collapse = "")
}
