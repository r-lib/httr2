#' Simulate a request
#'
#' After preparing a request, call `req_fetch()` to perform it, fetching
#' the results back to R.
#'
#' @param req A [req]uest.
#' @param path Optionally, path to save body of request. This is useful for
#'   large responses since it avoids storing the response in memory.
#' @param handle Advanced use only; a curl handle.
#' @returns Returns an HTTP response.
#' @export
#' @examples
#' req("https://google.com") %>%
#'   req_fetch()
req_fetch <- function(req, path = NULL, handle = NULL) {
  check_request(req)
  handle <- handle %||% req_handle(req)

  max_tries <- retry_max_tries(req)
  deadline <- retry_deadline(req)

  i <- 0
  delay <- throttle_delay(req)

  while(i < max_tries && Sys.time() < deadline) {
    sys_sleep(delay)
    resp <- tryCatch(
      req_fetch1(req, path = path, handle = handle),
      error = function(err) err
    )

    if (is_error(resp)) {
      i <- i + 1
      delay <- retry_backoff(req, i)
    } else if (retry_is_transient(req, resp)) {
      i <- i + 1
      delay <- retry_after(req, resp) %||% retry_backoff(req, i)
    # } else if (auth_needs_reauth(req, resp)) {
    #   req <- auth_reauth(req)
    #   handle <- req_handle(req)
    } else {
      # done
      break
    }
  }

  if (is_error(resp)) {
    stop(resp)
  } else if (error_is_error(req, resp)) {
    resp_check_status(resp, error_info(req, resp))
  } else {
    resp
  }
}

req_fetch1 <- function(req, path = NULL, handle = NULL) {
  if (!is.null(path)) {
    res <- curl::curl_fetch_disk(req$url, path, handle)
    body <- new_path(path)
  } else {
    res <- curl::curl_fetch_memory(req$url, handle)
    body <- res$content
  }

  new_response(
    handle = handle,
    method = req$method %||% default_method(req),
    url = res$url,
    status_code = res$status_code,
    headers = curl::parse_headers_list(res$headers),
    body = body,
    times = res$times
  )
}

#' Perform a dry run
#'
#' This shows you exactly what httr2 will send to the server, without
#' actually sending anything. It requires the httpuv package because it
#' works by sending the real HTTP request to a local webserver, thanks to
#' the magic of [curl::curl_echo()].
#'
#' @inheritParams req_fetch
#' @param quiet If `TRUE` doesn't print anything.
#' @returns Invisibly, a list containing information about the request,
#'   including `method`, `path`, and `headers`.
#' @export
#' @examples
#' req("http://google.com") %>% req_dry_run()
req_dry_run <- function(req, quiet = FALSE) {
  check_request(req)
  check_installed("httpuv")

  if (!quiet) {
    req <- req_verbose(req, header_in = FALSE)
  }
  # Override local server with fake host
  req <- req_headers(req, "Host" = httr::parse_url(req$url)$hostname)

  handle <- req_handle(req)
  resp <- curl::curl_echo(handle, progress = FALSE)

  invisible(resp[c("method", "path", "headers")])
}

#' Perform a request, streaming data back to R
#'
#' After preparing a request, call `req_stream()` to perform the request
#' and handle the result with a streaming callback. This is useful for
#' streaming HTTP APIs where potentially the stream never ends.
#'
#' @inheritParams req_fetch
#' @param callback A single argument callback function. It will be called
#'   repeatedly with a raw vector whenever there is at least `buffer_kb`
#'   worth of data to process. It must return `TRUE` to continue streaming.
#' @param timeout_sec Number of seconds to processs stream for.
#' @param buffer_kb Buffer size, in kilobytes.
#' @export
#' @examples
#' show_bytes <- function(x) {
#'   cat("Got ", length(x), " bytes\n", sep = "")
#'   TRUE
#' }
#' resp <- req("http://httpbin.org/stream-bytes/100000") %>%
#'   req_stream(show_bytes, buffer_kb = 32)
req_stream <- function(req, callback, timeout_sec = Inf, buffer_kb = 64) {
  check_request(req)

  handle <- req_handle(req)
  callback <- as_function(callback)

  stopifnot(is.numeric(timeout_sec), timeout_sec > 0)
  stop_time <- Sys.time() + timeout_sec

  stream <- curl::curl(req$url, handle = handle)
  open(stream, "rb")
  withr::defer(close(stream))

  continue <- TRUE
  while(continue && isIncomplete(stream) && Sys.time() < stop_time) {
    buf <- readBin(stream, raw(), buffer_kb * 1024)
    if (length(buf) > 0) {
      continue <- isTRUE(callback(buf))
    }
  }

  data <- curl::handle_data(handle)
  new_response(
    handle = handle,
    method = req$method %||% default_method(req),
    url = data$url,
    status_code = data$status_code,
    headers = curl::parse_headers_list(data$headers),
    body = NULL,
    times = data$times
  )
}

req_handle <- function(req) {
  req <- req_method_apply(req)
  if (!has_name(req$options, "useragent")) {
    req <- req_user_agent(req, default_ua())
  }

  handle <- curl::new_handle()
  curl::handle_setheaders(handle, .list = req$headers)
  curl::handle_setopt(handle, .list = req$options)
  if (length(req$fields) > 0) {
    curl::handle_setform(handle, .list = req$fields)
  }

  handle
}

new_path <- function(x) structure(x, class = "httr_path")
is_path <- function(x) inherits(x, "httr_path")
