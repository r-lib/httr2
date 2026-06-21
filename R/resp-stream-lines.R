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
  splitter <- init_streaming_response(resp, LineSplitter)
  check_number_whole(lines, min = 0, allow_infinite = TRUE)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)
  if (lifecycle::is_present(warn) && !isFALSE(warn)) {
    lifecycle::deprecate_warn("1.2.3", "resp_stream_lines(warn)")
  }

  if (lines == 0) {
    return(character())
  }

  encoding <- env_cache(resp$cache, "encoding", resp_encoding(resp))
  blocks <- stream_pull(resp, lines, splitter, max_size)
  lines_read <- stream_parse_lines(blocks, encoding)
  if (resp_stream_show_body(resp)) {
    log_stream(lines_read)
  }
  lines_read
}

# Splits a stream into lines terminated by LF (and hence CRLF)
LineSplitter <- R6::R6Class(
  "LineSplitter",
  inherit = StreamSplitter,
  public = list(
    name = "resp_stream_lines()",
    find_boundaries = function(buffer) {
      grepRaw(as.raw(0x0A), buffer, fixed = TRUE, all = TRUE) + 1L
    },
    # At end of stream, a trailing line without a terminator is still a line.
    finish = function(remainder) {
      if (length(remainder) == 0L) list() else list(remainder)
    }
  )
)

# Decode raw line blocks (each a line plus its trailing LF or CRLF) into a
# character vector in `encoding`, dropping the terminators.
stream_parse_lines <- function(blocks, encoding) {
  text <- vapply(blocks, rawToChar, character(1))
  Encoding(text) <- "bytes"
  text <- iconv(text, encoding, "UTF-8")
  sub("\r?\n$", "", text)
}
