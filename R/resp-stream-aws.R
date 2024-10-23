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

  if (!is.null(event_bytes)) {
    parse_aws_event(event_bytes)
  } else {
    return(NULL)
  }
}

find_aws_event_boundary <- function(buffer) {
  # No valid AWS event message is less than 16 bytes
  if (length(buffer) < 16) {
    return(NULL)
  }

  # Read first 4 bytes as a big endian number
  event_size <- rawToInteger(buffer[1:4])
  if (event_size > length(buffer)) {
    return(NULL)
  }

  event_size + 1
}

parse_aws_event <- function(bytes) {
  # prelude
  total_length <- rawToInteger(bytes[1:4])
  header_length <- rawToInteger(bytes[5:8])
  prelude_crc <- rawToInteger(bytes[9:12])

  # payload
  headers_raw <- bytes[13:(13 + header_length - 1)]
  body_raw <- bytes[(13 + header_length):(total_length - 4)]
  crc_raw <- bytes[(total_length - 3):total_length]

  headers <- parse_headers(headers_raw)

  body <- rawToChar(body_raw)
  if (identical(headers$`:content-type`, "application/json")) {
    body <- jsonlite::parse_json(body)
  }

  list(headers = headers, body = body)
}


# Helpers ----------------------------------------------------------------

rawToInteger <- function(x) {
  readBin(x, "integer", n = 1, size = length(x), endian = "big")
}

# Equivalent boto coee:
# https://github.com/boto/botocore/blob/8e2e8fd7ab59f8c1337902acc32d2ee10cb184ad/botocore/eventstream.py
# https://github.com/lifion/lifion-aws-event-stream/blob/develop/lib/index.js#L194

unpack_value <- function(type, value) {
  if (type == 0) {
    TRUE
  } else if (type == 1) {
    FALSE
  } else if (type %in% 2:5) {
    # BYTE, SHORT, INTEGER, LONG
    rawToInteger(value)
  } else if (type == 6) {
    # BYTE ARRAY
    value
  } else if (type == 7) {
    # CHARACTER
    rawToChar(value)
  } else if (type == 8) {
    # TIMESTAMP
    .POSIXct(rawToInteger(value))
  } else if (type == 9) {
    # UUID
  }
}

parse_headers <- function(x) {
  headers <- list()

  i <- 1
  read_bytes <- function(n) {
    if (n == 0) {
      raw()
    }
    out <- x[i:(i + n - 1)]
    i <<- i + n
    out
  }

  while(i <= length(x)) {
    name_length <- as.integer(read_bytes(1))
    name <- rawToChar(read_bytes(name_length))
    type <- as.integer(read_bytes(1))
    length <- rawToInteger(read_bytes(2))
    value_raw <- read_bytes(length)
    headers[[name]] <- unpack_value(type, value_raw)
  }
  headers
}
