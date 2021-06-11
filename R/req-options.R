#' Set arbitrary curl options in request
#'
#' `req_options()` is for expert use only; it allows you to directly set
#' libcurl options to access features that are otherwise not available in
#' httr2.
#'
#' @inheritParams req_headers
#' @param ... Name-value pairs. The name should be a valid curl option,
#'   as found in [curl::curl_options()].
#' @keywords internal
#' @export
req_options <- function(.req, ...) {
  check_request(.req)

  .req$options <- modify_list(.req$options, ...)
  .req
}

#' Modify request user agent
#'
#' This overrides the default user agent set by httr2 which includes the
#' version numbers of httr2, the curl package, and libcurl.
#'
#' @inheritParams req_fetch
#' @param ua A new user-agent string.
#' @export
#' @examples
#' request("http://example.com") %>% req_dry_run()
#' request("http://example.com") %>% req_user_agent("MyPackage") %>% req_dry_run()
req_user_agent <- function(req, ua) {
  check_request(req)
  check_string(ua, "`ua`")

  req_options(req, useragent = ua)
}

default_ua <- function() {
  versions <- c(
    httr2 = as.character(utils::packageVersion("httr2")),
    `r-curl` = as.character(utils::packageVersion("curl")),
    libcurl = curl::curl_version()$version
  )
  paste0(names(versions), "/", versions, collapse = " ")
}

#' Set a request timeout
#'
#' An error will be thrown if the request does not complete in the time limit.
#'
#' @inheritParams req_fetch
#' @param seconds Maximum number of seconds to wait
#' @export
#' @examples
#' # Give up after at most 10 seconds
#' request("http://example.com") %>% req_timeout(10)
req_timeout <- function(req, seconds) {
  check_request(req)
  check_number(seconds, "`seconds`")

  if (seconds < 0.001) {
    abort("`timeout` must be >1 ms")
  }
  req_options(req, timeout_ms = seconds * 1000)
}

#' Show verbose output when request is performed
#'
#' @description
#' `req_verbose()` uses the following prefixes to distinguish between
#' different components of the HTTP requests and responses:
#'
#' * `* ` informative curl messages
#' * `<-` request headers
#' * `<<` request body
#' * `->` response headers
#' * `>>` response body
#'
#' @inheritParams req_fetch
#' @param header_req,header_resp Show request/response headers?
#' @param body_req,body_resp Should request/response bodies? When the response
#'   body is compressed, this will show the number of bytes recevied in
#'   each "chunk".
#' @param info Show informational text from curl? This is mainly useful
#'   for debugging https and auth problems, so is disabled by default.
#' @param redact_header Redact confidential data in the headers? Currently
#'   redacts the contents of the Authorization header to prevent you from
#'   accidentally leaking credentials when debugging/reprexing.
#' @seealso [req_fetch()] which exposes a limited subset of these options
#'   through the `verbosity` argument.
#' @export
req_verbose <- function(req,
                        header_req = TRUE,
                        header_resp = TRUE,
                        body_req = FALSE,
                        body_resp = FALSE,
                        info = FALSE,
                        redact_header = TRUE) {
  check_request(req)

  debug <- function(type, msg) {
    switch(type + 1,
      text =       if (info)            prefix_message("*  ", msg),
      headerOut =  if (header_resp)     prefix_message("<- ", msg, redact = redact_header),
      headerIn =   if (header_req)      prefix_message("-> ", msg),
      dataOut =    if (body_resp)       prefix_message("<< ", msg),
      dataIn =     if (body_req)        prefix_message(">> ", msg)
    )
  }
  req_options(req, debugfunction = debug, verbose = TRUE)
}

# helpers -----------------------------------------------------------------

prefix_message <- function(prefix, x, redact = FALSE) {

  if (any(x > 128)) {
    # This doesn't handle unicode, but it seems like most output
    # will be compressed in some way, so displaying bodies is unlikely
    # to be useful anyway.
    lines <- paste0(length(x), " bytes of binary data")
  } else {
    x <- readBin(x, character())
    lines <- unlist(strsplit(x, "\r?\n", useBytes = TRUE))
    if (redact) {
      is_auth <- grepl("^[aA]uthorization: ", lines)
      lines[is_auth] <- "Authorization: <REDACTED>"
    }
  }
  out <- paste0(prefix, lines, collapse = "\n")
  cat(out, "\n", sep = "")
}
