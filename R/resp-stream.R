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
  check_streaming_response(resp, reader = "raw")
  check_number_decimal(kb, min = 0, allow_infinite = FALSE)

  out <- resp$body$read(kb * 1024)
  if (resp_stream_show_body(resp)) {
    log_stream("Streamed ", length(out), " bytes")
    cli::cat_line()
  }
  out
}

#' @export
#' @rdname resp_stream_raw
#' @order 6
resp_stream_is_complete <- function(resp) {
  check_streaming_response(resp)
  !stream_has_buffered(resp) && resp$body$is_complete()
}

# Is there any data still buffered in the response that hasn't been returned to
# the user yet? (Either raw bytes or decoded-but-unserved blocks.)
stream_has_buffered <- function(resp) {
  cache <- resp$cache
  if (length(cache$push_back %||% raw()) > 0) {
    return(TRUE)
  }

  pos <- cache$block_pos %||% 1L
  pos <= length(cache$block_queue %||% list())
}

#' @export
#' @param ... Not used; included for compatibility with generic.
#' @rdname resp_stream_raw
#' @order 5
close.httr2_response <- function(con, ...) {
  check_response(con)

  if (inherits(con$body, "StreamingBody")) {
    con$body$close()
  }

  invisible()
}

# Streaming engine ------------------------------------------------------------

# How many bytes to read from the connection at a time when streaming.
stream_chunk_bytes <- 64L * 1024L

# Reads from a streaming response and uses `splitter` to divide the byte stream
# into blocks, returning up to `n` of them in a list. The byte-level details -
# where blocks begin and end, how trailing bytes are handled at the end of the
# stream, and how many bytes to read at a time - all live in the `splitter`
# (a `StreamSplitter`), so that this loop can be shared by lines, server-sent
# events, and AWS events.
#
# A whole chunk is split at once and the resulting blocks are held in a queue
# served by an index pointer, so that reading a few blocks at a time doesn't
# repeatedly rescan and recopy the buffered bytes.
stream_pull <- function(resp, n, splitter, max_size) {
  cache <- resp$cache
  queue <- cache$block_queue %||% list()
  pos <- cache$block_pos %||% 1L

  # Accumulate served slices in a list and flatten once at the end, so serving
  # many blocks (e.g. `lines = Inf`) doesn't repeatedly recopy a growing vector.
  serve <- list()
  n_out <- 0L
  repeat {
    # Serve whatever is already queued.
    available <- length(queue) - pos + 1L
    if (available > 0L) {
      take <- min(available, n - n_out)
      serve[[length(serve) + 1L]] <- queue[pos:(pos + take - 1L)]
      pos <- pos + take
      n_out <- n_out + take
    }
    if (n_out >= n) {
      break
    }

    # The queue is exhausted; combine any buffered bytes with a fresh read and
    # split the next batch of blocks. We always reparse the buffered bytes (not
    # just freshly read ones), because data may have been buffered by an earlier
    # call that didn't find a complete block.
    push_back <- cache$push_back %||% raw()
    if (length(push_back) > splitter$max_remainder_size(max_size)) {
      stop_stream_size(max_size)
    }
    chunk <- resp$body$read(splitter$read_cap(push_back, max_size))
    buffer <- c(push_back, chunk)
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

    # Preserve newly read bytes if splitting fails, so retrying sees the same
    # input rather than silently losing bytes already consumed from the body.
    cache$push_back <- buffer
    parsed <- splitter$split(buffer)

    if (any(parsed$sizes > max_size)) {
      stop_stream_size(max_size)
    }
    if (length(parsed$remainder) > splitter$max_remainder_size(max_size)) {
      stop_stream_size(max_size)
    }
    cache$push_back <- parsed$remainder

    if (length(parsed$blocks) > 0L) {
      queue <- parsed$blocks
      pos <- 1L
      # Keep the newly parsed queue recoverable until this call returns. If a
      # later read or split fails, retrying will serve these blocks again.
      cache$block_queue <- queue
      cache$block_pos <- pos
      next
    }

    # No complete block available from the current buffer.
    if (length(chunk) == 0L) {
      if (resp$body$is_complete()) {
        # The stream has ended; let the splitter flush any trailing bytes.
        remainder <- cache$push_back %||% raw()
        if (length(remainder) > max_size) {
          stop_stream_size(max_size)
        }
        final <- splitter$finish(remainder)
        if (length(final) > 0L) {
          serve[[length(serve) + 1L]] <- final
        }
        cache$push_back <- raw()
      }
      # Either EOF, or no data currently available (non-blocking).
      break
    }
    # We read new bytes but still don't have a complete block; loop to read more.
  }

  # Drop the queue once it's been fully served, so its blocks can be freed.
  if (pos > length(queue)) {
    queue <- list()
    pos <- 1L
  }
  cache$block_queue <- queue
  cache$block_pos <- pos

  unlist(serve, recursive = FALSE, use.names = FALSE)
}

# A `StreamSplitter` knows how to divide the byte stream of a particular format
# into blocks. `stream_pull()` handles the connection reads and queueing and
# delegates the format-specific decisions to a subclass.
StreamSplitter <- R6::R6Class(
  "StreamSplitter",
  public = list(
    delimiter_size = 0L,
    # Divide `buffer` into complete `blocks`, their wire `sizes`, and a raw
    # `remainder` of trailing bytes that don't yet form a complete block. Size
    # limits are enforced by `stream_pull()`.
    # nocov start: abstract defaults, always overridden by a subclass.
    split = function(buffer) {
      cli::cli_abort("Not implemented.", .internal = TRUE)
    },
    # Maximum size of an incomplete block, including the longest possible
    # partial delimiter.
    max_remainder_size = function(max_size) {
      max_size + max(self$delimiter_size - 1L, 0L)
    },
    # Emit any final blocks once the stream has ended with `remainder` bytes
    # left over after the last complete block.
    finish = function(remainder) {
      list()
    },
    # nocov end
    # How many bytes to read from the connection next, given the bytes already
    # buffered in `push_back`. Don't read more than one content byte past the
    # size limit; the extra byte lets us detect an oversized block or complete
    # a format-specific delimiter prefix.
    read_cap = function(push_back, max_size) {
      if (is.finite(max_size)) {
        remaining <- self$max_remainder_size(max_size) - length(push_back)
        min(stream_chunk_bytes, max(remaining + 1L, 1L))
      } else {
        stream_chunk_bytes
      }
    }
  )
)

# Splits a stream into blocks separated by boundaries located by
# `find_boundaries()`, which takes a raw vector and returns an integer vector
# of split points: the position one past the end of each complete block. Used
# by both server-sent events and AWS events.
BoundarySplitter <- R6::R6Class(
  "BoundarySplitter",
  inherit = StreamSplitter,
  public = list(
    find_boundaries = NULL,
    block_size = NULL,
    initialize = function(
      find_boundaries,
      block_size = length,
      delimiter_size = 0L
    ) {
      self$find_boundaries <- find_boundaries
      self$block_size <- block_size
      self$delimiter_size <- delimiter_size
    },
    split = function(buffer) {
      splits <- self$find_boundaries(buffer)
      if (length(splits) == 0L) {
        return(list(blocks = list(), remainder = buffer, sizes = numeric()))
      }
      starts <- c(1L, splits[-length(splits)])
      blocks <- lapply(seq_along(splits), function(i) {
        buffer[starts[i]:(splits[i] - 1L)]
      })
      last <- splits[length(splits)]
      remainder <- if (last > length(buffer)) {
        raw()
      } else {
        buffer[last:length(buffer)]
      }
      sizes <- vapply(blocks, self$block_size, numeric(1))
      list(blocks = blocks, remainder = remainder, sizes = sizes)
    },
    finish = function(remainder) {
      if (length(remainder) == 0L) {
        return(list())
      }
      cli::cli_warn("Premature end of input; ignoring final partial chunk")
      list()
    }
  )
)

stop_stream_size <- function(max_size, call = caller_env()) {
  cli::cli_abort(
    "Streaming read exceeded size limit of {max_size}",
    class = "httr2_streaming_error",
    call = call
  )
}

# Helpers ----------------------------------------------------

check_streaming_response <- function(
  resp,
  reader = NULL,
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

  if (!is.null(reader)) {
    previous <- resp$cache$stream_reader
    if (is.null(previous)) {
      resp$cache$stream_reader <- reader
    } else if (!identical(previous, reader)) {
      current_fun <- paste0("resp_stream_", reader, "()")
      previous_fun <- paste0("resp_stream_", previous, "()")
      cli::cli_abort(
        "Can't use {current_fun} after {previous_fun} on the same response.",
        class = "httr2_streaming_error",
        call = call
      )
    }
  }
}

resp_stream_show_body <- function(resp) {
  resp$request$policies$show_streaming_body %||% FALSE
}
resp_stream_show_buffer <- function(resp) {
  resp$request$policies$show_streaming_buffer %||% FALSE
}
