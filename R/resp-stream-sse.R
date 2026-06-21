#' @param max_size The maximum number of bytes to buffer while waiting for a
#'   line or event boundary; if exceeded, an error is thrown. This limit is
#'   approximate: to spot a boundary httr2 may buffer a handful of bytes beyond
#'   `max_size` (e.g. the bytes of the delimiter itself).
#' @export
#' @rdname resp_stream_raw
#' @order 3
resp_stream_sse <- function(resp, max_size = Inf) {
  check_streaming_response(resp, reader = "sse")
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)

  splitter <- env_cache(
    resp$cache,
    "boundary_splitter",
    BoundarySplitter$new(find_event_boundaries)
  )

  repeat {
    blocks <- stream_pull(resp, 1, splitter, max_size)
    if (length(blocks) == 0L) {
      return()
    }
    event_bytes <- blocks[[1L]]

    if (resp_stream_show_buffer(resp)) {
      log_stream(
        cli::rule("Raw server sent event"),
        "\n",
        rawToChar(event_bytes),
        prefix = "*  "
      )
    }

    event <- parse_event(event_bytes)
    if (!is.null(event)) break
  }

  if (resp_stream_show_body(resp)) {
    for (key in names(event)) {
      log_stream(cli::style_bold(key), ": ", pretty_json(event[[key]]))
    }
    cli::cat_line()
  }
  event
}

# Find every event boundary in a buffer, returning a vector of split points
# (the position one past the end of each boundary). Events may be separated by
# a double LF, a double CR, or a double CRLF.
#
# Example:
#   find_event_boundaries(charToRaw("data: 1\n\nid: 12345"))
# Returns:
#   9L  (so the first event is bytes 1:8, "data: 1\n\n")
find_event_boundaries <- function(buffer) {
  nn <- grepRaw("\n\n", buffer, fixed = TRUE, all = TRUE)
  rr <- grepRaw("\r\r", buffer, fixed = TRUE, all = TRUE)
  rnrn <- grepRaw("\r\n\r\n", buffer, fixed = TRUE, all = TRUE)

  # Fast paths for the common case of a single, consistent delimiter.
  if (length(rr) == 0L && length(rnrn) == 0L) {
    return(nn + 2L)
  }
  if (length(nn) == 0L && length(rnrn) == 0L) {
    return(rr + 2L)
  }
  if (length(nn) == 0L && length(rr) == 0L) {
    return(rnrn + 4L)
  }

  # Mixed delimiters: merge candidates and walk them left to right, taking
  # non-overlapping boundaries.
  starts <- c(nn, rr, rnrn)
  ends <- c(nn + 1L, rr + 1L, rnrn + 3L)
  o <- order(starts)
  starts <- starts[o]
  ends <- ends[o]

  keep <- logical(length(starts))
  consumed <- 0L
  for (k in seq_along(starts)) {
    if (starts[k] > consumed) {
      keep[k] <- TRUE
      consumed <- ends[k]
    }
  }
  ends[keep] + 1L
}

# https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
parse_event <- function(event_data) {
  if (is.raw(event_data)) {
    # Streams must be decoded using the UTF-8 decode algorithm.
    str_data <- rawToChar(event_data)
    Encoding(str_data) <- "UTF-8"
  } else {
    # for testing
    str_data <- event_data
  }

  # The stream must then be parsed by reading everything line by line, with a
  # U+000D CARRIAGE RETURN U+000A LINE FEED (CRLF) character pair, a single
  # U+000A LINE FEED (LF) character not preceded by a U+000D CARRIAGE RETURN
  # (CR) character, and a single U+000D CARRIAGE RETURN (CR) character not
  # followed by a U+000A LINE FEED (LF) character being the ways in
  # which a line can end.
  lines <- strsplit(str_data, "\r\n|\r|\n")[[1]]

  # When a stream is parsed, a data buffer, an event type buffer, and a
  # last event ID buffer must be associated with it. They must be initialized
  # to the empty string.
  data <- ""
  type <- ""
  last_id <- ""

  # If the line starts with a U+003A COLON character (:) - Ignore the line.
  lines <- lines[!grepl("^:", lines)]

  # If the line contains a U+003A COLON character (:)
  # * Collect the characters on the line before the first U+003A COLON
  #  character (:), and let field be that string.
  # * Collect the characters on the line after the first U+003A COLON character
  #  (:), and let value be that string. If value starts with a U+0020 SPACE
  #  character, remove it from value.
  m <- regexec("([^:]*)(: ?)?(.*)", lines)
  matches <- regmatches(lines, m)
  keys <- c("event", vapply(matches, function(x) x[2], character(1)))
  values <- c("message", vapply(matches, function(x) x[4], character(1)))

  for (i in seq_along(matches)) {
    key <- matches[[i]][2]
    value <- matches[[i]][4]

    if (key == "event") {
      # Set the event type buffer to field value.
      type <- value
    } else if (key == "data") {
      # Append the field value to the data buffer, then append a single
      # U+000A LINE FEED (LF) character to the data buffer.
      data <- paste0(data, value, "\n")
    } else if (key == "id") {
      # If the field value does not contain U+0000 NULL, then set the last
      # event ID buffer to the field value. Otherwise, ignore the field.
      last_id <- value
    }
  }

  # If the data buffer is an empty string, set the data buffer and the event
  # type buffer to the empty string and return.
  if (data == "") {
    return()
  }

  # If the data buffer's last character is a U+000A LINE FEED (LF) character,
  # then remove the last character from the data buffer.
  if (grepl("\n$", data)) {
    data <- substr(data, 1, nchar(data) - 1)
  }
  if (type == "") {
    type <- "message"
  }

  list(
    type = type,
    data = data,
    id = last_id
  )
}
