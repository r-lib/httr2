#' @export
#' @rdname resp_stream_raw
#' @param lines The maximum number of lines to return at once.
#' @param warn `r lifecycle::badge("deprecated")` `resp_stream_lines()` no longer
#'   warns when the connection ends without a final EOL, so this argument is
#'   ignored.
#' @order 2
resp_stream_lines <- function(
  resp,
  lines = 1,
  max_size = Inf,
  warn = deprecated()
) {
  check_streaming_response(resp)
  check_number_whole(lines, min = 0, allow_infinite = TRUE)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)
  if (lifecycle::is_present(warn) && !isFALSE(warn)) {
    lifecycle::deprecate_warn("1.2.3", "resp_stream_lines(warn)")
  }

  if (lines == 0) {
    # If you want to do that, who am I to judge?
    return(character())
  }

  cache <- resp$cache
  # The encoding can't change over the life of a response, so parse it once.
  encoding <- env_cache(cache, "stream_encoding", resp_encoding(resp))
  # The splitter is created once and reused across calls.
  splitter <- env_cache(cache, "line_splitter", LineSplitter$new(encoding))

  serve <- stream_pull(resp, lines, splitter, max_size)

  lines_read <- unlist(serve, use.names = FALSE) %||% character()
  if (resp_stream_show_body(resp)) {
    log_stream(lines_read)
  }
  lines_read
}

# Splits a stream into lines of text, with line endings of LF, CR, or CRLF
# (matching `readLines()`). A trailing bare CR is held in the remainder in case
# it's the first half of a CRLF split across reads (see `stream_split_lines()`).
LineSplitter <- R6::R6Class(
  "LineSplitter",
  inherit = StreamSplitter,
  public = list(
    encoding = NULL,
    initialize = function(encoding) {
      self$encoding <- encoding
    },
    split = function(buffer, max_size) {
      parsed <- stream_split_lines(buffer, self$encoding, max_size)
      list(blocks = as.list(parsed$lines), remainder = parsed$remainder)
    },
    finish = function(remainder) {
      if (length(remainder) == 0L) {
        return(list())
      }
      # A trailing bare CR is a line ending now that the stream has ended.
      if (remainder[[length(remainder)]] == as.raw(0x0D)) {
        remainder <- remainder[-length(remainder)]
      }
      list(stream_decode(remainder, self$encoding))
    }
  )
)

# Split `buffer` into complete lines plus a trailing remainder of bytes that do
# not yet form a complete line. Line endings may be LF, CR, or CRLF, matching
# the behaviour of `readLines()`.
#
# A bare CR at the very end of the buffer is left in the remainder, because it
# may be the first half of a CRLF split across reads. It resolves on the next
# read (or is treated as a line ending by `finish()` at end-of-stream).
#
# @returns A list with components `lines` (a character vector) and `remainder`
#   (a raw vector).
stream_split_lines <- function(buffer, encoding, max_size) {
  LF <- as.raw(0x0A)
  CR <- as.raw(0x0D)

  if (length(buffer) == 0L) {
    return(list(lines = character(), remainder = raw()))
  }

  lf <- grepRaw(LF, buffer, fixed = TRUE, all = TRUE)
  cr <- grepRaw(CR, buffer, fixed = TRUE, all = TRUE)
  # A trailing bare CR may be the first half of a CRLF split across reads, so
  # leave it in the remainder to resolve on the next read.
  if (length(cr) > 0L && cr[length(cr)] == length(buffer)) {
    cr <- cr[-length(cr)]
  }
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
    return(list(lines = character(), remainder = buffer))
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

  text <- rawToChar(region)
  Encoding(text) <- "bytes"
  lines <- strsplit(text, "\r\n|\r|\n", useBytes = TRUE)[[1]]

  list(
    lines = iconv(lines, encoding, "UTF-8"),
    remainder = remainder
  )
}

# Decode a raw vector of bytes into a single string in the response encoding.
stream_decode <- function(bytes, encoding) {
  text <- rawToChar(bytes)
  Encoding(text) <- "bytes"
  iconv(text, encoding, "UTF-8")
}
