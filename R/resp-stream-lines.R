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

# Splits a stream into lines of text terminated by LF or CRLF. A bare CR is not
# treated as a line ending (see `stream_split_lines()`).
LineSplitter <- R6::R6Class(
  "LineSplitter",
  inherit = StreamSplitter,
  public = list(
    encoding = NULL,
    initialize = function(encoding) {
      self$encoding <- encoding
    },
    split = function(buffer, max_size) {
      stream_split_lines(buffer, self$encoding, max_size)
    },
    finish = function(remainder) {
      if (length(remainder) == 0L) {
        list()
      } else {
        list(stream_decode(remainder, self$encoding))
      }
    }
  )
)

# Split `buffer` into complete lines plus a trailing remainder of bytes that do
# not yet form a complete line. Lines are terminated by LF or CRLF; a bare CR is
# treated as an ordinary character, not a line ending.
#
# We only ever split on LF, so a CRLF split across reads needs no special
# handling: the trailing CR is just unfinished line content that stays in the
# remainder until the next read supplies its LF.
#
# @returns A list matching the `StreamSplitter$split()` contract: `blocks` (a
#   list of decoded lines) and `remainder` (a raw vector).
stream_split_lines <- function(buffer, encoding, max_size) {
  LF <- as.raw(0x0A)
  ends <- grepRaw(LF, buffer, fixed = TRUE, all = TRUE)

  if (length(ends) == 0L) {
    if (length(buffer) > max_size) {
      stop_stream_size(max_size)
    } else {
      return(list(blocks = list(), remainder = buffer))
    }
  }

  cut <- ends[length(ends)] + 1L
  region <- buffer[seq_len(cut - 1L)]
  remainder <- buffer[seq2(cut, length(buffer))]

  # Enforce the per-line size limit (the span includes the line ending bytes).
  if (is.finite(max_size)) {
    line_starts <- c(1L, ends[-length(ends)] + 1L)
    spans <- (ends + 1L) - line_starts
    if (max(spans, length(remainder)) > max_size) {
      stop_stream_size(max_size)
    }
  }

  text <- stream_decode(region, encoding)
  list(
    blocks = as.list(strsplit(text, "\r\n|\n")[[1]]),
    remainder = remainder
  )
}

# Decode a raw vector of bytes into a single string in the response encoding.
stream_decode <- function(bytes, encoding) {
  text <- rawToChar(bytes)
  Encoding(text) <- "bytes"
  iconv(text, encoding, "UTF-8")
}
