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
#' req("http://example.com") %>% req_dry_run()
#' req("http://example.com") %>% req_user_agent("MyPackage") %>% req_dry_run()
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

#' Authenticate request with HTTP basic authentication
#'
#' This sets the Authorization header. See details at
#' <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>.
#'
#' @inheritParams req_fetch
#' @param user_name,password User name and password pair.
#' @export
#' @examples
#' req("http://example.com") %>%
#'   req_auth_basic("hadley", "my-secret-password") %>%
#'   req_dry_run()
#'
#' # Note that the authorization header is not encrypted and the
#' # password can easily be restored:
#' rawToChar(jsonlite::base64_dec("aGFkbGV5Om15LXNlY3JldC1wYXNzd29yZA=="))
#' # This means that you should be careful when sharing any code that
#' # reveals the Authorization header
req_auth_basic <- function(req, user_name, password) {
  check_request(req)
  check_string(user_name, "`user_name`")
  check_string(password, "`password`")

  req_options(req,
    httpauth = auth_flags("basic"),
    userpwd = paste0(user_name, ":", password)
  )
}

#' Authenticate request with bearer token
#'
#' A bearer token gives the bearer access to confidential resources
#' (so you should keep them secure like you would with a user name and
#' password). They are usually produced by some large authentication scheme
#' (like the various OAuth 2.0 flows), but you are sometimes given then
#' directly.
#'
#' @seealso [RFC750](https://datatracker.ietf.org/doc/html/rfc6750)
#'   The OAuth 2.0 Authorization Framework: Bearer Token Usage
#' @inheritParams req_fetch
#' @param token A bearer token
#' @export
req_auth_bearer_token <- function(req, token) {
  check_request(req)
  check_string(token, "`token`")
  req_headers(req, Authorization = paste("Bearer", token))
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
#' req("http://example.com") %>% req_timeout(10)
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
#' different components of the http messages:
#'
#' * `*` informative curl messages
#' * `->` headers sent (out)
#' * `>>` data sent (out)
#' * `*>` ssl data sent (out)
#' * `<-` headers received (in)
#' * `<<` data received (in)
#' * `<*` ssl data received (in)
#'
#' @inheritParams req_fetch
#' @param header_out,header_in Show headers sent to/received from the server?
#' @param data_out,data_in Show data sent to/received from the server?
#' @param info Show informational text from curl. This is mainly useful
#'   for debugging https and auth problems, so is disabled by default.
#' @param ssl Show data even when using a secure connection?
#' @export
req_verbose <- function(req,
                        header_out = TRUE,
                        header_in = TRUE,
                        data_out = TRUE,
                        data_in = FALSE,
                        info = FALSE,
                        ssl = FALSE) {
  check_request(req)

  debug <- function(type, msg) {
    switch(type + 1,
      text =       if (info)            prefix_message("*  ", msg),
      headerIn =   if (header_in)       prefix_message("<- ", msg),
      headerOut =  if (header_out)      prefix_message("-> ", msg),
      dataIn =     if (data_in)         prefix_message("<<  ", msg),
      dataOut =    if (data_out)        prefix_message(">> ", msg),
      sslDataIn =  if (ssl && data_in)  prefix_message("*< ", msg),
      sslDataOut = if (ssl && data_out) prefix_message("*> ", msg)
    )
  }
  req_options(req, debugfunction = debug, verbose = TRUE)
}

# helpers -----------------------------------------------------------------

prefix_message <- function(prefix, x) {
  x <- readBin(x, character())

  lines <- unlist(strsplit(x, "\n", fixed = TRUE, useBytes = TRUE))
  out <- paste0(prefix, lines, collapse = "\n")

  cat(out, "\n", sep = "")
}

auth_flags <- function(type) {
  constants <- c(
    basic = 1,
    digest = 2,
    gssnegotiate = 4,
    ntlm = 8,
    digest_ie = 16,
    any = -17
  )
  type <- arg_match0(type, names(constants), "type")
  constants[[type]]
}
