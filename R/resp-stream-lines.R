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
  check_streaming_response(resp, reader = "lines")
  check_number_whole(lines, min = 0, allow_infinite = TRUE)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)
  if (lifecycle::is_present(warn) && !isFALSE(warn)) {
    lifecycle::deprecate_warn("1.2.3", "resp_stream_lines(warn)")
  }

  if (lines == 0) {
    # If you want to do that, who am I to judge?
    return(character())
  }

  # The splitter is created once and reused across calls.
  splitter <- env_cache(
    resp$cache,
    "line_splitter",
    LineSplitter$new(resp_encoding(resp))
  )

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
    delimiter_size = 2L,
    initialize = function(encoding) {
      self$encoding <- encoding
    },
    split = function(buffer) {
      stream_split_lines(buffer, self$encoding)
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
#   list of decoded lines), `sizes` (their wire sizes without delimiters), and
#   `remainder` (a raw vector).
stream_split_lines <- function(buffer, encoding = "UTF-8") {
  LF <- as.raw(0x0A)
  ends <- grepRaw(LF, buffer, fixed = TRUE, all = TRUE)

  if (length(ends) == 0L) {
    return(list(blocks = list(), remainder = buffer, sizes = numeric()))
  }

  cut <- ends[length(ends)] + 1L
  region <- buffer[seq_len(cut - 1L)]
  remainder <- buffer[seq2(cut, length(buffer))]

  sizes <- diff(c(0L, ends)) - 1L
  has_content <- sizes > 0L
  sizes[has_content] <- sizes[has_content] -
    (buffer[ends[has_content] - 1L] == as.raw(0x0D))

  text <- stream_decode(region, encoding)
  list(
    blocks = as.list(strsplit(text, "\r\n|\n")[[1]]),
    remainder = remainder,
    sizes = sizes
  )
}

# Decode a raw vector of bytes into a single string in the response encoding.
stream_decode <- function(bytes, encoding) {
  text <- rawToChar(bytes)
  Encoding(text) <- "bytes"
  iconv(text, encoding, "UTF-8")
}
