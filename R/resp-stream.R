#' Read a streaming body a chunk at a time
#'
#' @description
#' * `resp_stream_raw()` retrieves bytes (`raw` vectors).
#' * `resp_stream_lines()` retrieves lines of text (`character` vectors).
#' * `resp_stream_sse()` retrieves a single [server-sent
#'   event](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events).
#' * `resp_stream_aws()` retrieves a single event from an AWS stream
#'   (i.e. mime type `application/vnd.amazon.eventstream``).
#'
#' Use `resp_stream_is_complete()` to determine if there is further data
#' waiting on the stream.
#'
#' @returns
#' * `resp_stream_raw()`: a raw vector.
#' * `resp_stream_lines()`: a character vector.
#' * `resp_stream_sse()`: a list with components `type`, `data`, and `id`.
#'   `type`, `data`, and `id` are always strings; `data` and `id` may be empty
#'   strings.
#' * `resp_stream_aws()`: a list with components `headers` and `body`.
#'   `body` will be automatically parsed if the event contents a `:content-type`
#'   header with `application/json`.
#'
#' `resp_stream_sse()` and `resp_stream_aws()` will return `NULL` to signal that
#' the end of the stream has been reached or, if in nonblocking mode, that
#' no event is currently available.
#' @export
#' @param resp,con A streaming [response] created by [req_perform_connection()].
#' @param kb How many kilobytes (1024 bytes) of data to read.
#' @order 1
#' @examples
#' req <- request(example_url()) |>
#'   req_template("GET /stream/:n", n = 5)
#'
#' con <- req |> req_perform_connection()
#' while (!resp_stream_is_complete(con)) {
#'   lines <- con |> resp_stream_lines(2)
#'   cat(length(lines), " lines received\n", sep = "")
#' }
#' close(con)
#'
#' # You can also see what's happening by setting verbosity
#' con <- req |> req_perform_connection(verbosity = 2)
#' while (!resp_stream_is_complete(con)) {
#'   lines <- con |> resp_stream_lines(2)
#' }
#' close(con)
resp_stream_raw <- function(resp, kb = 32) {
  check_streaming_response(resp)

  out <- resp$body$read(kb * 1024)
  if (resp_stream_show_body(resp)) {
    log_stream("Streamed ", length(out), " bytes")
    cli::cat_line()
  }
  out
}

#' @export
#' @rdname resp_stream_raw
#' @param lines The maximum number of lines to return at once.
#' @param warn Like [readLines()]: warn if the connection ends without a final
#'   EOL.
#' @order 1
resp_stream_lines <- function(resp, lines = 1, max_size = Inf, warn = TRUE) {
  check_streaming_response(resp)
  check_number_whole(lines, min = 0, allow_infinite = TRUE)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)
  check_logical(warn)

  if (lines == 0) {
    # If you want to do that, who am I to judge?
    return(character())
  }

  cache <- resp$cache
  # The encoding can't change over the life of a response, so parse it once.
  encoding <- cache$stream_encoding %||%
    (cache$stream_encoding <- resp_encoding(resp))

  # Lines are decoded a whole chunk at a time and held in a queue, so that
  # repeated small reads (e.g. `lines = 1`) don't repeatedly rescan and copy
  # the buffered bytes. `pos` is the index of the next line to return.
  queue <- cache$stream_lines_queue %||% character()
  pos <- cache$stream_lines_pos %||% 1L

  serve <- list()
  n_served <- 0L

  repeat {
    available <- length(queue) - pos + 1L
    if (available > 0L) {
      take <- min(available, lines - n_served)
      serve[[length(serve) + 1L]] <- queue[pos:(pos + take - 1L)]
      pos <- pos + take
      n_served <- n_served + take
    }
    if (n_served >= lines) {
      break
    }

    # The queue is exhausted; combine any buffered bytes with a fresh read and
    # decode the next batch of lines. We always reparse the buffered bytes (not
    # just freshly read ones), because data may have been buffered by an earlier
    # call that didn't find a complete line.
    chunk <- resp$body$read(stream_chunk_bytes)
    buffer <- c(cache$push_back %||% raw(), chunk)
    if (length(buffer) == 0L) {
      break
    }

    if (length(chunk) > 0L && resp_stream_show_buffer(resp)) {
      log_stream(cli::rule("Buffer"), prefix = "*  ")
      log_stream(
        "Received chunk: ",
        paste(as.character(chunk), collapse = " "),
        prefix = "*  "
      )
    }

    # Keep the full buffer in place so an over-size error is reproducible.
    cache$push_back <- buffer
    parsed <- stream_split_lines(
      buffer,
      encoding = encoding,
      eat_lf = isTRUE(cache$eat_next_lf),
      max_size = max_size
    )
    cache$eat_next_lf <- parsed$eat_lf
    cache$push_back <- parsed$remainder

    if (length(parsed$lines) > 0L) {
      queue <- parsed$lines
      pos <- 1L
      next
    }

    # No complete line available from the current buffer.
    if (length(chunk) == 0L) {
      if (resp$body$is_complete()) {
        # The stream has ended; flush any trailing bytes as a final,
        # unterminated line.
        trailer <- cache$push_back %||% raw()
        if (length(trailer) > 0L) {
          if (warn) {
            cli::cli_warn("incomplete final line found")
          }
          serve[[length(serve) + 1L]] <- stream_decode(trailer, encoding)
          cache$push_back <- raw()
        }
      }
      # Either EOF, or no data currently available (non-blocking).
      break
    }
    # We read new bytes but still don't have a complete line; loop to read more.
  }

  cache$stream_lines_queue <- queue
  cache$stream_lines_pos <- pos

  lines_read <- unlist(serve, use.names = FALSE) %||% character()
  if (resp_stream_show_body(resp)) {
    log_stream(lines_read)
  }
  lines_read
}


#' @param max_size The maximum number of bytes to buffer; once this number of
#'   bytes has been exceeded without a line/event boundary, an error is thrown.
#' @export
#' @rdname resp_stream_raw
#' @order 1
resp_stream_sse <- function(resp, max_size = Inf) {
  repeat {
    event_bytes <- resp_boundary_pushback(
      resp,
      max_size,
      find_event_boundaries,
      include_trailer = FALSE
    )
    if (is.null(event_bytes)) {
      return()
    }

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

#' @export
#' @rdname resp_stream_raw
resp_stream_is_complete <- function(resp) {
  check_response(resp)
  !stream_has_buffered(resp) && resp$body$is_complete()
}

# Is there any data still buffered in the response that hasn't been returned to
# the user yet? (Either raw bytes, decoded lines, or decoded event blocks.)
stream_has_buffered <- function(resp) {
  cache <- resp$cache
  if (length(cache$push_back %||% raw()) > 0) {
    return(TRUE)
  }

  lines_pos <- cache$stream_lines_pos %||% 1L
  if (length(cache$stream_lines_queue %||% character()) - lines_pos + 1L > 0L) {
    return(TRUE)
  }

  boundary_pos <- cache$boundary_pos %||% 1L
  if (
    !is.null(cache$boundary_queue) &&
      boundary_pos <= length(cache$boundary_queue)
  ) {
    return(TRUE)
  }

  FALSE
}

#' @export
#' @param ... Not used; included for compatibility with generic.
#' @rdname resp_stream_raw
#' @order 3
close.httr2_response <- function(con, ...) {
  check_response(con)

  if (inherits(con$body, "StreamingBody")) {
    con$body$close()
  }

  invisible()
}

# How many bytes to read from the connection at a time when streaming lines.
stream_chunk_bytes <- 64L * 1024L

# Raw bytes for the line endings we recognise.
LF <- as.raw(0x0A)
CR <- as.raw(0x0D)

# Decode a raw vector of bytes into a single string in the response encoding.
stream_decode <- function(bytes, encoding) {
  text <- rawToChar(bytes)
  Encoding(text) <- "bytes"
  iconv(text, encoding, "UTF-8")
}

# Split `buffer` into complete lines plus a trailing remainder of bytes that do
# not yet form a complete line. Line endings may be LF, CR, or CRLF, matching
# the behaviour of `readLines()`.
#
# A lone CR at the very end of the buffer is treated as a line ending (so the
# line is emitted immediately), but `eat_lf` is set so that a following LF -
# which may be the second half of a CRLF split across reads - is dropped on the
# next call.
#
# @param eat_lf Should a leading LF be dropped (because the previous buffer
#   ended in a bare CR)?
# @returns A list with components `lines` (a character vector), `remainder`
#   (a raw vector), and `eat_lf` (a logical).
stream_split_lines <- function(buffer, encoding, eat_lf, max_size) {
  if (eat_lf && length(buffer) >= 1L) {
    if (buffer[[1L]] == LF) {
      buffer <- buffer[-1L]
    }
    eat_lf <- FALSE
  }
  if (length(buffer) == 0L) {
    return(list(lines = character(), remainder = raw(), eat_lf = eat_lf))
  }

  lf <- grepRaw(LF, buffer, fixed = TRUE, all = TRUE)
  cr <- grepRaw(CR, buffer, fixed = TRUE, all = TRUE)
  if (length(cr) == 0L) {
    # Fast path: the common case of LF-delimited text (e.g. ndjson).
    ends <- lf
    next_start <- lf + 1L
  } else {
    # Drop LFs that are the second half of a CRLF pair.
    lf_solo <- lf[!((lf - 1L) %in% cr)]
    ends <- sort(c(cr, lf_solo))
    next_start <- ends + 1L
    crlf <- (buffer[ends] == CR) & ((ends + 1L) %in% lf)
    next_start[crlf] <- ends[crlf] + 2L
  }

  if (length(ends) == 0L) {
    if (length(buffer) > max_size) {
      stop_stream_size(max_size)
    }
    return(list(lines = character(), remainder = buffer, eat_lf = FALSE))
  }

  cut <- next_start[length(next_start)]
  region <- if (cut == 1L) raw() else buffer[seq_len(cut - 1L)]
  remainder <- if (cut > length(buffer)) raw() else buffer[cut:length(buffer)]

  # Enforce the per-line size limit (the span includes the line ending bytes).
  if (is.finite(max_size)) {
    line_starts <- c(1L, next_start[-length(next_start)])
    spans <- next_start - line_starts
    if (max(spans, length(remainder)) > max_size) {
      stop_stream_size(max_size)
    }
  }

  # A trailing bare CR may be the first half of a CRLF split across reads.
  eat_lf <- length(cr) > 0L &&
    ends[length(ends)] == length(buffer) &&
    buffer[[length(buffer)]] == CR

  text <- rawToChar(region)
  Encoding(text) <- "bytes"
  lines <- strsplit(text, "\r\n|\r|\n", useBytes = TRUE)[[1]]

  list(
    lines = iconv(lines, encoding, "UTF-8"),
    remainder = remainder,
    eat_lf = eat_lf
  )
}

stop_stream_size <- function(max_size, call = caller_env()) {
  cli::cli_abort(
    "Streaming read exceeded size limit of {max_size}",
    class = "httr2_streaming_error",
    call = call
  )
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

# How many bytes to read from the connection at a time when streaming events.
boundary_chunk_bytes <- 64L * 1024L

# Reads from a streaming response and splits it into "blocks" delimited by
# boundaries found by `find_boundaries`. Like `resp_stream_lines()`, a whole
# chunk is split at once and the resulting blocks are held in a queue, so that
# reading events one at a time doesn't repeatedly rescan and recopy the buffer.
#
# @param max_size Maximum number of bytes to buffer before a boundary is found
#   before throwing an error.
# @param find_boundaries A function that takes a raw vector and returns an
#   integer vector of split points: the position one past the end of each
#   complete block in the buffer.
# @param include_trailer If TRUE, at the end of the response, if there are
#   bytes after the last boundary, then return those bytes; if FALSE, then those
#   bytes are discarded with a warning.
resp_boundary_pushback <- function(
  resp,
  max_size,
  find_boundaries,
  include_trailer
) {
  check_streaming_response(resp)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)

  cache <- resp$cache

  # Serve a previously-decoded block if one is queued.
  queue <- cache$boundary_queue
  pos <- cache$boundary_pos %||% 1L
  if (!is.null(queue) && pos <= length(queue)) {
    block <- queue[[pos]]
    if (pos + 1L > length(queue)) {
      cache$boundary_queue <- NULL
      cache$boundary_pos <- 1L
    } else {
      cache$boundary_pos <- pos + 1L
    }
    return(block)
  }

  repeat {
    # Don't read more than one byte past the size limit; the extra byte lets us
    # detect that the limit has been exceeded.
    cap <- if (is.finite(max_size)) {
      max(max_size - length(cache$push_back %||% raw()) + 1L, 1L)
    } else {
      boundary_chunk_bytes
    }
    chunk <- resp$body$read(min(boundary_chunk_bytes, cap))
    buffer <- c(cache$push_back %||% raw(), chunk)
    if (length(buffer) == 0L) {
      return(NULL)
    }

    if (length(chunk) > 0L && resp_stream_show_buffer(resp)) {
      log_stream(cli::rule("Buffer"), prefix = "*  ")
      log_stream(
        "Received chunk: ",
        paste(as.character(chunk), collapse = " "),
        prefix = "*  "
      )
    }

    splits <- find_boundaries(buffer)
    if (length(splits) > 0L) {
      starts <- c(1L, splits[-length(splits)])
      blocks <- lapply(seq_along(splits), function(i) {
        buffer[starts[i]:(splits[i] - 1L)]
      })
      last <- splits[length(splits)]
      cache$push_back <- if (last > length(buffer)) {
        raw()
      } else {
        buffer[last:length(buffer)]
      }
      if (length(blocks) > 1L) {
        cache$boundary_queue <- blocks
        cache$boundary_pos <- 2L
      }
      return(blocks[[1L]])
    }

    # No complete block in the buffer.
    if (length(buffer) > max_size) {
      # Keep the buffer in place, so that if the user tries again they'll get
      # the same error rather than reading the stream having missed bytes.
      cache$push_back <- buffer
      cli::cli_abort(
        "Streaming read exceeded size limit of {max_size}",
        class = "httr2_streaming_error"
      )
    }

    if (length(chunk) == 0) {
      if (resp$body$is_complete()) {
        # We've truly reached the end of the connection; no more data is coming.
        if (include_trailer) {
          cache$push_back <- raw()
          return(buffer)
        } else {
          cli::cli_warn("Premature end of input; ignoring final partial chunk")
          cache$push_back <- raw()
          return(NULL)
        }
      } else {
        # More data might come later; store the buffer and return NULL.
        cache$push_back <- buffer
        return(NULL)
      }
    }

    # More data was received but no complete block yet; loop to read more.
    cache$push_back <- buffer
  }
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

# Helpers ----------------------------------------------------

check_streaming_response <- function(
  resp,
  arg = caller_arg(resp),
  call = caller_env()
) {
  check_response(resp, arg = arg, call = call)

  if (resp_body_type(resp) != "stream") {
    stop_input_type(
      resp,
      "a streaming HTTP response object",
      allow_null = FALSE,
      arg = arg,
      call = call
    )
  }

  if (!resp$body$is_open()) {
    cli::cli_abort("{.arg {arg}} has already been closed.", call = call)
  }
}

# isOpen doesn't work for two reasons:
# 1. It errors if con has been closed, rather than returning FALSE
# 2. If returns TRUE if con has been closed and a new connection opened
#
# So instead we retrieve the connection from its number and compare to the
# original connection. This works because connections have an undocumented
# external pointer.
isValid <- function(con) {
  tryCatch(
    identical(getConnection(con), con),
    error = function(cnd) FALSE
  )
}

resp_stream_show_body <- function(resp) {
  resp$request$policies$show_streaming_body %||% FALSE
}
resp_stream_show_buffer <- function(resp) {
  resp$request$policies$show_streaming_buffer %||% FALSE
}
