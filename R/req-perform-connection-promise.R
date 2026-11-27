#' Perform a request asynchronously and return a streaming connection
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This variation on [req_perform_connection()] returns a [promises::promise()]
#' immediately and opens the connection in the background, so the event loop
#' stays responsive while waiting for the server to respond. The promise
#' resolves to a streaming [response] as soon as the response headers have
#' been received. You can then use [resp_stream_raw()], [resp_stream_lines()],
#' [resp_stream_sse()], or [resp_stream_aws()] to read the body. Reads never
#' block: if no data is available yet, they return an empty result, and you can
#' use `resp$body$get_fdset()` with [later::later_fd()] to wait asynchronously
#' for more data. Functions that read the whole body, such as
#' [resp_body_string()], wait for the transfer to finish and block the event
#' loop while they wait. Always finish up by calling `close(response)`.
#'
#' If the server returns an HTTP error, the promise rejects with the same
#' error that [req_perform_connection()] would throw, after the complete error
#' body has been received asynchronously.
#'
#' Like [req_perform_promise()], `req_perform_connection_promise()`:
#'
#' * Will not retrieve a new OAuth token if it expires after the promised
#'   request is created but before it is actually requested.
#' * Does not perform throttling with [req_throttle()].
#' * Does not attempt retries as described by [req_retry()].
#'
#' @inheritParams req_perform_connection
#' @return A [promises::promise()] that resolves to a streaming [response] if
#'   successful or rejects on the same errors thrown by
#'   [req_perform_connection()].
#' @export
#' @examples
#' \dontrun{
#' req <- request(example_url()) |>
#'   req_template("GET /stream/:n", n = 5)
#'
#' p <- req_perform_connection_promise(req)
#' promises::then(p, function(resp) {
#'   lines <- resp_stream_lines(resp, Inf)
#'   cat(length(lines), " lines received so far\n", sep = "")
#'   close(resp)
#' })
#' }
req_perform_connection_promise <- function(
  req,
  verbosity = NULL,
  mock = getOption("httr2_mock", NULL)
) {
  check_installed(c("promises", "later"))

  check_request(req)
  mock <- as_mock_function(mock)
  req <- req_verbosity_connection(req, verbosity %||% httr2_verbosity())
  req <- req_policies(req, connection = TRUE)
  error_call <- current_env()

  promises::promise(function(resolve, reject) {
    if (!is.null(mock)) {
      mock_resp <- mock(req)
      if (!is.null(mock_resp)) {
        return(resolve(handle_resp(req, mock_resp, error_call = error_call)))
      }
    }

    req_prep <- req_prepare(req)
    handle <- req_handle(req_prep)
    # Async request spans should not become the active span
    req_prep <- req_with_span(req_prep, activate = FALSE)
    tryCatch(
      handle_preflight(req_prep, handle),
      error = function(cnd) {
        req_record_span_status(req_prep)
        cnd_signal(cnd)
      }
    )

    the$last_request <- req
    the$last_response <- NULL
    signal(class = "httr2_perform_connection")

    resolve(open_connection_promise(req, req_prep, handle, error_call))
  })
}

open_connection_promise <- function(req, req_prep, handle, error_call) {
  conn <- curl::curl(req$url, handle = handle)
  body <- StreamingBody$new(conn)

  settled <- FALSE
  finish <- function(span_value = NULL) {
    if (!settled) {
      settled <<- TRUE
      req_completed(req_prep)
      req_record_span_status(req_prep, span_value)
    }
  }

  wrap_curl <- function(code) {
    tryCatch(
      code,
      error = function(err) {
        cnd <- curl_cnd(err, call = error_call)
        cnd$request <- req
        cnd_signal(cnd)
      }
    )
  }

  p <- promises::promise(function(resolve, reject) {
    wrap_curl(suppressWarnings(open(conn, "rbfs", blocking = FALSE)))
    resolve(poll_connection_until(conn, \() wrap_curl(curl::curl_ready(conn))))
  })
  p <- promises::then(p, function(...) {
    resp <- create_response(req, curl::handle_data(handle), body)
    if (!error_is_error(req, resp)) {
      finish(resp)
      return(resp)
    }

    # HTTP error: read the full error body asynchronously before rejecting
    chunks <- list()
    read_chunk <- function() {
      chunk <- wrap_curl(body$read(64 * 1024))
      if (length(chunk) > 0) {
        chunks[[length(chunks) + 1L]] <<- chunk
      }
      body$is_complete()
    }

    promises::then(poll_connection_until(conn, read_chunk), function(...) {
      body$close()
      bytes <- unlist(chunks, recursive = FALSE, use.names = FALSE)
      resp$body <- if (length(bytes) > 0) bytes
      the$last_response <- resp
      cnd <- resp_failure_cnd(req, resp, error_call = error_call)
      finish(resp)
      cnd_signal(cnd)
    })
  })

  promises::catch(p, function(cnd) {
    body$close()
    finish(if (inherits(cnd, "httr2_failure")) cnd)
    cnd_signal(cnd)
  })
}

# Polls a non-blocking curl connection on the current event loop until
# `step()` returns TRUE.
poll_connection_until <- function(conn, step) {
  loop <- later::current_loop()
  promises::promise(function(resolve, reject) {
    poll <- function() {
      tryCatch(
        {
          if (step()) {
            resolve(NULL)
            return()
          }
          fds <- curl::multi_fdset(conn)
          later::later_fd(
            func = \(ready) poll(),
            readfds = fds$reads,
            writefds = fds$writes,
            exceptfds = fds$exceptions,
            # curl reports milliseconds and later expects seconds.
            timeout = fds$timeout / 1000,
            loop = loop
          )
        },
        error = reject
      )
    }
    poll()
  })
}
