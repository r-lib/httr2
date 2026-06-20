# Helpers for building AWS event-stream messages in tests.

# Decode a hex string to raw. Only used to express opaque reference vectors
# captured from another implementation; build events with aws_event() instead.
hex_to_raw <- function(x) {
  x <- gsub("(\\s|\n)+", "", x)
  pairs <- substring(x, seq(1, nchar(x), by = 2), seq(2, nchar(x), by = 2))
  as.raw(strtoi(pairs, 16L))
}

# A big-endian unsigned integer in `size` raw bytes (handles values beyond
# .Machine$integer.max, unlike writeBin()).
aws_uint <- function(x, size) {
  x <- as.numeric(x)
  out <- raw(size)
  for (i in seq_len(size)) {
    out[[size - i + 1L]] <- as.raw(x %% 256)
    x <- x %/% 256
  }
  out
}

# An 8-byte big-endian IEEE double, as read back by parse_int64().
aws_double <- function(x) {
  writeBin(as.double(x), raw(), size = 8L, endian = "big")
}

# CRC32 of `bytes` as 4 big-endian raw bytes, matching the AWS event-stream
# framing.
aws_crc <- function(bytes) {
  hex <- digest::digest(bytes, algo = "crc32", serialize = FALSE)
  as.raw(strtoi(substring(hex, c(1L, 3L, 5L, 7L), c(2L, 4L, 6L, 8L)), 16L))
}

# A single header: a `name`, a `type` (matching the AWS event-stream spec), and
# a `value` to encode.
aws_header <- function(name, type, value = NULL) {
  body <- switch(
    type,
    true = list(tag = 0L, bytes = raw()),
    false = list(tag = 1L, bytes = raw()),
    byte = list(tag = 2L, bytes = aws_uint(value, 1L)),
    short = list(tag = 3L, bytes = aws_uint(value, 2L)),
    integer = list(tag = 4L, bytes = aws_uint(value, 4L)),
    long = list(tag = 5L, bytes = aws_double(value)),
    bytes = list(tag = 6L, bytes = c(aws_uint(length(value), 2L), value)),
    string = list(
      tag = 7L,
      bytes = c(aws_uint(nchar(value), 2L), charToRaw(value))
    ),
    timestamp = list(tag = 8L, bytes = aws_double(value)),
    uuid = list(tag = 9L, bytes = value),
    unknown = list(tag = 255L, bytes = raw()),
    cli::cli_abort("Unknown header type {.val {type}}.")
  )
  c(aws_uint(nchar(name), 1L), charToRaw(name), as.raw(body$tag), body$bytes)
}

# A complete event wrapping raw `headers` and a raw `body` in the AWS
# event-stream framing, computing the prelude/header lengths and both CRCs.
aws_event <- function(headers = raw(), body = raw()) {
  total <- 12L + length(headers) + length(body) + 4L
  prelude <- c(aws_uint(total, 4L), aws_uint(length(headers), 4L))
  prelude <- c(prelude, aws_crc(prelude)) # prelude CRC over the first 8 bytes
  message <- c(prelude, headers, body)
  c(message, aws_crc(message)) # message CRC over everything before it
}
