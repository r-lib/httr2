
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
#' @inheritParams req_perform_stream
#' @param blocking When retrieving data, should the connection block and wait
#'   for the desired information or immediately return what it has (possibly
#'   nothing)?
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
req_perform_connection <- function(req, blocking = TRUE) {
  check_request(req)
  check_bool(blocking)

  req <- auth_sign(req)
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

  if (error_is_error(req, resp)) {
    # Read full body if there's an error
    conn <- resp$body
    resp$body <- read_con(conn)
    close(conn)
  }
  the$last_response <- resp
  handle_resp(req, resp)

  resp
}

req_perform_connection1 <- function(req, handle, blocking = TRUE) {
  stream <- curl::curl(req$url, handle = handle)

  # Must open the stream in order to initiate the connection
  open(stream, "rbf", blocking = blocking)
  curl_data <- curl::handle_data(handle)

  new_response(
    method = req_method_get(req),
    url = curl_data$url,
    status_code = curl_data$status_code,
    headers = as_headers(curl_data$headers),
    body = stream,
    request = req
  )
}
