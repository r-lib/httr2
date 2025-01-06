#' Read a streaming body a chunk at a time
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
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
#' * `resp_stream_sse()`: a list with components `type`, `data`, and `id`
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
  conn <- resp$body

  out <- readBin(conn, raw(), kb * 1024)
  if (resp_stream_is_verbose(resp)) {
    cli::cat_line("<< Streamed ", length(out), " bytes")
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

  encoding <- resp_encoding(resp)

  lines_read <- character(0)
  while (lines > 0) {
    line <- resp_stream_oneline(resp, max_size, warn, encoding)
    if (length(line) == 0) {
      # No more data, either because EOF or req_perform_connection(blocking=FALSE).
      # Either way we're done
      break
    }
    lines_read <- c(lines_read, line)
    lines <- lines - 1
  }

  if (resp_stream_is_verbose(resp)) {
    cli::cat_line("<< ", lines_read)
    cli::cat_line()
  }

  lines_read
}


#' @param max_size The maximum number of bytes to buffer; once this number of
#'   bytes has been exceeded without a line/event boundary, an error is thrown.
#' @export
#' @rdname resp_stream_raw
#' @order 1
resp_stream_sse <- function(resp, max_size = Inf) {
  event_bytes <- resp_boundary_pushback(resp, max_size, find_event_boundary, include_trailer = FALSE)
  if (is.null(event_bytes)) {
    return()
  }

  event <- parse_event(event_bytes)
  if (resp_stream_is_verbose(resp)) {
    for (key in names(event)) {
      cli::cat_line("< ", key, ": ", event[[key]])
    }
    cli::cat_line()
  }
  event
}

#' @export
#' @rdname resp_stream_raw
resp_stream_is_complete <- function(resp) {
  check_response(resp)
  length(resp$cache$push_back) == 0 && !isIncomplete(resp$body)
}

#' @export
#' @param ... Not used; included for compatibility with generic.
#' @rdname resp_stream_raw
#' @order 3
close.httr2_response <- function(con, ...) {
  check_response(con)

  if (inherits(con$body, "connection") && isValid(con$body)) {
    close(con$body)
  }

  invisible()
}

resp_stream_oneline <- function(resp, max_size, warn, encoding) {
  repeat {
    line_bytes <- resp_boundary_pushback(resp, max_size, find_line_boundary, include_trailer = TRUE)
    if (is.null(line_bytes)) {
      return(character())
    }

    eat_next_lf <- resp$cache$resp_stream_oneline_eat_next_lf
    resp$cache$resp_stream_oneline_eat_next_lf <- FALSE

    if (identical(line_bytes, as.raw(0x0A)) && isTRUE(eat_next_lf)) {
      # We hit that special edge case, see below
      next
    }

    # If ending on \r, there's a special edge case here where if the
    # next line begins with \n, that byte should be eaten.
    if (utils::tail(line_bytes, 1) == 0x0D) {
      resp$cache$resp_stream_oneline_eat_next_lf <- TRUE
    }

    # Use `resp$body` as the variable name so that if warn=TRUE, you get
    # "incomplete final line found on 'resp$body'" as the warning message
    `resp$body` <- line_bytes
    line_con <- rawConnection(`resp$body`)
    on.exit(close(line_con))

    # readLines chomps the trailing newline. I assume this is desirable.
    raw_text <- readLines(line_con, n = 1, warn = warn)

    # Use iconv to convert from whatever encoding is specified in the
    # response header, to UTF-8
    return(iconv(raw_text, encoding, "UTF-8"))
  }
}

find_line_boundary <- function(buffer) {
  if (length(buffer) == 0) {
    return(NULL)
  }

  # Look left 1 byte
  right1 <- c(utils::tail(buffer, -1), 0x00)

  crlf <- buffer == 0x0D & right1 == 0x0A
  cr <- buffer == 0x0D
  lf <- buffer == 0x0A

  all <- which(crlf | cr | lf)
  if (length(all) == 0) {
    return(NULL)
  }

  first <- all[[1]]
  if (crlf[first]) {
    return(first + 2)
  } else {
    return(first + 1)
  }
}

# Function to find the first double line ending in a buffer, or NULL if no
# double line ending is found
#
# Example:
#   find_event_boundary(charToRaw("data: 1\n\nid: 12345"))
# Returns:
#   list(
#     matched = charToRaw("data: 1\n\n"),
#     remaining = charToRaw("id: 12345")
#   )
find_event_boundary <- function(buffer) {
  if (length(buffer) < 2) {
    return(NULL)
  }

  # leftX means look behind by X bytes. For example, left1[2] equals buffer[1].
  # Any attempt to read past the beginning of the buffer results in 0x00.
  left1 <- c(0x00, utils::head(buffer, -1))
  left2 <- c(0x00, utils::head(left1, -1))
  left3 <- c(0x00, utils::head(left2, -1))

  boundary_end <- which(
    (left1 == 0x0A & buffer == 0x0A) | # \n\n
      (left1 == 0x0D & buffer == 0x0D) | # \r\r
      (left3 == 0x0D & left2 == 0x0A & left1 == 0x0D & buffer == 0x0A) # \r\n\r\n
  )

  if (length(boundary_end) == 0) {
    return(NULL) # No event boundary found
  }

  boundary_end <- boundary_end[1] # Take the first occurrence
  split_at <- boundary_end + 1 # Split at one after the boundary
  split_at
}

# Splits a buffer into the part before `split_at`, and the part starting at
# `split_at`. It's possible for either of the returned parts to be zero-length
# (i.e. if `split_at` is 1 or length(buffer)+1).
split_buffer <- function(buffer, split_at) {
  # Return a list with the event data and the remaining buffer
  list(
    matched = slice(buffer, end = split_at),
    remaining = slice(buffer, start = split_at)
  )
}

# @param max_size Maximum number of bytes to look for a boundary before throwing an error
# @param boundary_func A function that takes a raw vector and returns NULL if no
#   boundary was detected, or one position PAST the end of the first boundary in
#   the vector
# @param include_trailer If TRUE, at the end of the response, if there are
#   bytes after the last boundary, then return those bytes; if FALSE, then those
#   bytes are silently discarded.
resp_boundary_pushback <- function(resp, max_size, boundary_func, include_trailer) {
  check_streaming_response(resp)
  check_number_whole(max_size, min = 1, allow_infinite = TRUE)

  chunk_size <- min(max_size + 1, 1024)

  # Grab data left over from last resp_stream_sse() call (if any)
  buffer <- resp$cache$push_back %||% raw()
  resp$cache$push_back <- raw()

  print_buffer <- function(buf, label) {
    # cat(label, ":", paste(sprintf("%02X", as.integer(buf)), collapse = " "), "\n", file = stderr())
  }

  # Read chunks until we find an event or reach the end of input
  repeat {
    # Try to find an event boundary using the data we have
    print_buffer(buffer, "Buffer to parse")
    split_at <- boundary_func(buffer)

    if (!is.null(split_at)) {
      result <- split_buffer(buffer, split_at)
      # We found a complete event
      print_buffer(result$matched, "Matched data")
      print_buffer(result$remaining, "Remaining buffer")
      resp$cache$push_back <- result$remaining
      return(result$matched)
    }

    if (length(buffer) > max_size) {
      # Keep the buffer in place, so that if the user tries resp_stream_sse
      # again, they'll get the same error rather than reading the stream
      # having missed a bunch of bytes.
      resp$cache$push_back <- buffer
      cli::cli_abort("Streaming read exceeded size limit of {max_size}")
    }

    # We didn't have enough data. Attempt to read more
    chunk <- readBin(resp$body, raw(),
      # Don't let us exceed the max size by more than one byte; we do allow the
      # one extra byte so we know to error.
      n = min(chunk_size, max_size - length(buffer) + 1)
    )

    print_buffer(chunk, "Received chunk")

    # If we've reached the end of input, store the buffer and return NULL
    if (length(chunk) == 0) {
      if (!isIncomplete(resp$body)) {
        # We've truly reached the end of the connection; no more data is coming
        if (include_trailer && length(buffer) > 0) {
          return(buffer)
        } else {
          return(NULL)
        }
      }

      # More data might come later
      print_buffer(buffer, "Storing incomplete buffer")
      resp$cache$push_back <- buffer
      return(NULL)
    }

    # More data was received; combine it with existing buffer and continue the
    # loop to try parsing again
    buffer <- c(buffer, chunk)
    print_buffer(buffer, "Combined buffer")
  }
}

parse_event <- function(event_data) {
  # always treat event_data as UTF-8, it's in the spec
  str_data <- rawToChar(event_data)
  Encoding(str_data) <- "UTF-8"

  # The spec says \r\n, \r, and \n are all valid separators
  lines <- strsplit(str_data, "\r\n|\r|\n")[[1]]

  m <- regexec("([^:]*)(: ?)?(.*)", lines)
  matches <- regmatches(lines, m)
  keys <- c("event", vapply(matches, function(x) x[2], character(1)))
  values <- c("message", vapply(matches, function(x) x[4], character(1)))

  remove_dupes <- duplicated(keys, fromLast = TRUE) & keys != "data"
  keys <- keys[!remove_dupes]
  values <- values[!remove_dupes]

  event_type <- values[keys == "event"]
  data <- values[keys == "data"]
  id <- values[keys == "id"]

  list(
    type = event_type,
    data = data,
    id = id
  )
}

# Helpers ----------------------------------------------------


check_streaming_response <- function(resp,
                                     arg = caller_arg(resp),
                                     call = caller_env()) {
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

  if (!isValid(resp$body)) {
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

resp_stream_is_verbose <- function(resp) {
  resp$request$policies$show_streaming_body %||% FALSE
}
