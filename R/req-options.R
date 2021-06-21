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

#' Set user-agent
#'
#' This overrides the default user-agent set by httr2 which includes the
#' version numbers of httr2, the curl package, and libcurl.
#'
#' @inheritParams req_perform
#' @param string String to be sent in the `User-Agent` header.
#' @param versions Named character vector used to construct a user-agent
#'   string using a lightweight convention. If both `string` and `versions`
#'   are omitted,
#' @export
#' @examples
#' # Default user-agent:
#' request("http://example.com") %>% req_dry_run()
#'
#' request("http://example.com") %>% req_user_agent("MyString") %>% req_dry_run()
#'
#' # If you're wrapping in an API in a package, it's polite to set the
#' # user agent to identify your package.
#' request("http://example.com") %>%
#'   req_user_agent(versions = c("MyPackage" = "1.1.2")) %>%
#'   req_dry_run()
req_user_agent <- function(req, string = NULL, versions = NULL) {
  check_request(req)

  if (is.null(string) && is.null(versions)) {
    # Used in req_handle() to set default
    return(req_user_agent(req, versions = c(
        httr2 = utils::packageVersion("httr2"),
        `r-curl` = utils::packageVersion("curl"),
        libcurl = curl::curl_version()$version
      )))
  } else if (!is.null(string) && is.null(versions)) {
    check_string(string, "`string`")
    ua <- string
  } else if (!is.null(versions) && is.null(string)) {
    ua <- paste0(names(versions), "/", versions, collapse = " ")
  } else {
    abort("Must supply one of `string` and `versions`")
  }

  req_options(req, useragent = ua)
}

#' Set time limit
#'
#' An error will be thrown if the request does not complete in the time limit.
#'
#' @inheritParams req_perform
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

#' Show extra output when request is performed
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
#' @inheritParams req_perform
#' @param header_req,header_resp Show request/response headers?
#' @param body_req,body_resp Should request/response bodies? When the response
#'   body is compressed, this will show the number of bytes recevied in
#'   each "chunk".
#' @param info Show informational text from curl? This is mainly useful
#'   for debugging https and auth problems, so is disabled by default.
#' @param redact_headers Redact confidential data in the headers? Currently
#'   redacts the contents of the Authorization header to prevent you from
#'   accidentally leaking credentials when debugging/reprexing.
#' @seealso [req_perform()] which exposes a limited subset of these options
#'   through the `verbosity` argument.
#' @export
req_verbose <- function(req,
                        header_req = TRUE,
                        header_resp = TRUE,
                        body_req = FALSE,
                        body_resp = FALSE,
                        info = FALSE,
                        redact_headers = TRUE) {
  check_request(req)

  debug <- function(type, msg) {
    switch(type + 1,
      text =       if (info)        verbose_message("*  ", msg),
      headerOut =  if (header_resp) verbose_header("<- ", msg),
      headerIn =   if (header_req)  verbose_header("-> ", msg, redact_headers),
      dataOut =    if (body_resp)   verbose_message("<< ", msg),
      dataIn =     if (body_req)    verbose_message(">> ", msg)
    )
  }
  req_options(req, debugfunction = debug, verbose = TRUE)
}

# helpers -----------------------------------------------------------------

verbose_message <- function(prefix, x) {
  if (any(x > 128)) {
    # This doesn't handle unicode, but it seems like most output
    # will be compressed in some way, so displaying bodies is unlikely
    # to be useful anyway.
    lines <- paste0(length(x), " bytes of binary data")
  } else {
    x <- readBin(x, character())
    lines <- unlist(strsplit(x, "\r?\n", useBytes = TRUE))
  }
  cli::cat_line(prefix, lines)
}

verbose_header <- function(prefix, x, redact = TRUE) {
  x <- readBin(x, character())
  lines <- unlist(strsplit(x, "\r?\n", useBytes = TRUE))

  for (line in lines) {
    if (grepl(":", line, fixed = TRUE)) {
      header <- headers_redact(as_headers(line), redact)
      cli::cat_line(prefix, cli::style_bold(names(header)), ": ", header)
    } else {
      cli::cat_line(prefix, line)
    }
  }
}
