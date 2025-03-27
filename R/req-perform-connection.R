#' Perform a request and return a streaming connection
#'
#' @description
#' Use `req_perform_connection()` to perform a request if you want to stream the
#' response body. A response returned by `req_perform_connection()` includes a
#' connection as the body. You can then use [resp_stream_raw()],
#' [resp_stream_lines()], or [resp_stream_sse()] to retrieve data a chunk at a
#' time. Always finish up by closing the connection by calling
#' `close(response)`.
#'
#' This is an alternative interface to [req_perform_stream()] that returns a
#' [connection][base::connections] that you can use to pull the data, rather
#' than providing callbacks that the data is pushed to. This is useful if you
#' want to do other work in between handling inputs from the stream.
#'
#' @inheritParams req_perform
#' @param blocking When retrieving data, should the connection block and wait
#'   for the desired information or immediately return what it has (possibly
#'   nothing)?
#' @param verbosity How much information to print? This is a wrapper
#'   around [req_verbose()] that uses an integer to control verbosity:
#'
#'   * `0`: no output
#'   * `1`: show headers
#'   * `2`: show headers and bodies as they're streamed
#'   * `3`: show headers, bodies, curl status messages, raw SSEs, and stream
#'     buffer management
#'
#'   Use [with_verbosity()] to control the verbosity of requests that
#'   you can't affect directly.
#' @export
#' @examples
#' req <- request(example_url()) |>
#'   req_url_path("/stream-bytes/32768")
#' resp <- req_perform_connection(req)
#'
#' length(resp_stream_raw(resp, kb = 16))
#' length(resp_stream_raw(resp, kb = 16))
#' # When the stream has no more data, you'll get an empty result:
#' length(resp_stream_raw(resp, kb = 16))
#'
#' # Always close the response when you're done
#' close(resp)
#'
#' # You can loop until complete with resp_stream_is_complete()
#' resp <- req_perform_connection(req)
#' while (!resp_stream_is_complete(resp)) {
#'   print(length(resp_stream_raw(resp, kb = 12)))
#' }
#' close(resp)
req_perform_connection <- function(req, blocking = TRUE, verbosity = NULL) {
  check_request(req)
  check_bool(blocking)
  # verbosity checked in req_verbosity_connection

  req <- req_verbosity_connection(req, verbosity %||% httr2_verbosity())
  req_prep <- req_prepare(req)
  handle <- req_handle(req_prep)
  the$last_request <- req
  the$last_response <- NULL

  tries <- 0
  delay <- 0
  max_tries <- retry_max_tries(req)
  deadline <- Sys.time() + retry_max_seconds(req)
  resp <- NULL
  while (tries < max_tries && Sys.time() < deadline) {
    retry_check_breaker(req, tries)
    sys_sleep(delay, "for retry backoff")

    if (!is.null(resp)) {
      close(resp)
    }
    resp <- req_perform_connection1(req, handle, blocking = blocking)

    if (retry_is_transient(req, resp)) {
      tries <- tries + 1

      delay <- retry_after(req, resp, tries)
      signal(class = "httr2_retry", tries = tries, delay = delay)
    } else {
      break
    }
  }
  req_completed(req)

  if (!is_error(resp) && error_is_error(req, resp)) {
    # Read full body if there's an error
    conn <- resp$body
    resp$body <- read_con(conn)
    the$last_response <- resp
    close(conn)
  }
  handle_resp(req, resp)

  resp
}

# Like req_verbosity() but we want to print the streaming body when it's
# requested not when curl actually receives it
req_verbosity_connection <- function(
  req,
  verbosity,
  error_call = caller_env()
) {
  if (!is_integerish(verbosity, n = 1) || verbosity < 0 || verbosity > 3) {
    cli::cli_abort("{.arg verbosity} must 0, 1, 2, or 3.", call = error_call)
  }

  req <- switch(
    verbosity + 1,
    req,
    req_verbose(req),
    req_verbose(req, body_req = TRUE),
    req_verbose(req, body_req = TRUE, info = TRUE)
  )
  if (verbosity > 1) {
    req <- req_policies(
      req,
      show_streaming_body = verbosity >= 2,
      show_streaming_buffer = verbosity >= 3
    )
  }
  req
}

req_perform_connection1 <- function(req, handle, blocking = TRUE) {
  the$last_request <- req
  the$last_response <- NULL
  signal(class = "httr2_perform_connection")

  err <- capture_curl_error({
    body <- curl::curl(req$url, handle = handle)
    # Must open the stream in order to initiate the connection
    suppressWarnings(open(body, "rbf", blocking = blocking))
  })
  if (is_error(err)) {
    close(body)
    return(err)
  }

  curl_data <- curl::handle_data(handle)

  the$last_response <- create_response(req, curl_data, body)
  the$last_response
}

# Make open mockable
open <- NULL
