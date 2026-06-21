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
  init_streaming_response(resp, RawSplitter)
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
  init_streaming_response(resp)
  !stream_has_buffered(resp) && resp$body$is_complete()
}

# Is there any data still buffered in the response that hasn't been returned to
# the user yet? (Either raw bytes or decoded-but-unserved blocks.)
stream_has_buffered <- function(resp) {
  cache <- resp$cache
  if (length(cache$push_back) > 0) {
    return(TRUE)
  }
  cache$block_pos <= length(cache$block_queue)
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
  queue <- cache$block_queue
  pos <- cache$block_pos

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

    push_back <- cache$push_back
    if (length(push_back) > max_size) {
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

    parsed <- splitter$split(buffer)
    cache$push_back <- parsed$remainder

    if (length(parsed$blocks) > 0L) {
      queue <- parsed$blocks
      pos <- 1L
      # Checkpoint the freshly parsed queue before serving from it: if a later
      # read trips the size limit, the errored call is retried and these blocks
      # are served again rather than lost (their bytes are already consumed).
      cache$block_queue <- queue
      cache$block_pos <- pos
      next
    }

    # No complete block available from the current buffer.
    if (length(chunk) == 0L) {
      if (resp$body$is_complete()) {
        # The stream has ended; let the splitter flush any trailing bytes.
        final <- splitter$finish(parsed$remainder)
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
    # The full name of the public reader (e.g. "resp_stream_lines()") this
    # splitter backs. Used to detect mixing readers on one response.
    name = NULL,
    # Constructed once per response by init_streaming_response(). Subclasses
    # that need to inspect the response (e.g. for its encoding) override this.
    initialize = function(resp = NULL) {},
    # Divide `buffer` into a list of complete `blocks` plus a raw `remainder`
    # of trailing bytes that don't yet form a complete block. The size limit is
    # enforced by `stream_pull()`, so `split()` itself never throws.
    # nocov start: abstract defaults, always overridden by a subclass.
    split = function(buffer) {
      cli::cli_abort("Not implemented.", .internal = TRUE)
    },
    # Emit any final blocks once the stream has ended with `remainder` bytes
    # left over after the last complete block.
    finish = function(remainder) {
      list()
    },
    # nocov end
    # How many bytes to read from the connection next, given the bytes already
    # buffered in `push_back`. Don't read more than one byte past the size
    # limit; the extra byte lets us detect that the buffer has overflowed.
    read_cap = function(push_back, max_size) {
      if (is.finite(max_size)) {
        min(stream_chunk_bytes, max(max_size - length(push_back) + 1L, 1L))
      } else {
        stream_chunk_bytes
      }
    }
  )
)

RawSplitter <- R6::R6Class(
  "RawSplitter",
  inherit = StreamSplitter,
  public = list(name = "resp_stream_raw()")
)

# Splits a stream into blocks separated by boundaries located by
# `find_boundaries()`, which takes a raw vector and returns an integer vector
# of split points: the position one past the end of each complete block.
# Subclasses (server-sent events, AWS events) supply `find_boundaries()` and a
# `name`.
BoundarySplitter <- R6::R6Class(
  "BoundarySplitter",
  inherit = StreamSplitter,
  public = list(
    # nocov start: abstract, always overridden by a subclass.
    find_boundaries = function(buffer) {
      cli::cli_abort("Not implemented.", .internal = TRUE)
    },
    # nocov end
    split = function(buffer) {
      splits <- self$find_boundaries(buffer)
      if (length(splits) == 0L) {
        return(list(blocks = list(), remainder = buffer))
      }
      
      starts <- c(1L, splits[-length(splits)])
      blocks <- lapply(seq_along(splits), function(i) {
        buffer[starts[i]:(splits[i] - 1L)]
      })
      remainder <- buffer[seq2(splits[[length(splits)]], length(buffer))]
      list(blocks = blocks, remainder = remainder)
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

# Validate a streaming response, initialize its cache, and (when a `splitter`
# generator is supplied) construct and cache the splitter. The cached splitter
# both drives the reads and records which reader is in use, so attempting a
# second, different reader on the same response errors. Returns the splitter,
# so callers can write `splitter <- init_streaming_response(resp, SseSplitter)`.
init_streaming_response <- function(
  resp,
  splitter = NULL,
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

  # Initialize the streaming cache so the read loop and stream_has_buffered()
  # can read these fields without `%||%` guards. Only fills missing fields, so
  # it preserves any bytes a caller has already pushed back.
  cache <- resp$cache
  cache$push_back <- cache$push_back %||% raw()
  cache$block_queue <- cache$block_queue %||% list()
  cache$block_pos <- cache$block_pos %||% 1L

  if (is.null(splitter)) {
    return(invisible(NULL))
  }

  # Construct the splitter once per response and cache it.
  cached <- cache$splitter
  if (is.null(cached)) {
    cache$splitter <- splitter$new(resp)
    return(invisible(cache$splitter))
  }
  if (!inherits(cached, splitter$classname)) {
    used <- splitter$new(resp)$name
    cli::cli_abort(
      "Can't use {used} after {cached$name} on the same response.",
      class = "httr2_streaming_error",
      call = call
    )
  }
  invisible(cached)
}

resp_stream_show_body <- function(resp) {
  resp$request$policies$show_streaming_body %||% FALSE
}
resp_stream_show_buffer <- function(resp) {
  resp$request$policies$show_streaming_buffer %||% FALSE
}
