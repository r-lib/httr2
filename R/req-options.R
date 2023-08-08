#' Set arbitrary curl options in request
#'
#' `req_options()` is for expert use only; it allows you to directly set
#' libcurl options to access features that are otherwise not available in
#' httr2.
#'
#' @inheritParams req_headers
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]> Name-value pairs. The name
#'   should be a valid curl option, as found in [curl::curl_options()].
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' # req_options() allows you to access curl options that are not otherwise
#' # exposed by httr2. For example, in very special cases you may need to
#' # turn off SSL verification. This is generally a bad idea so httr2 doesn't
#' # provide a convenient wrapper, but if you really know what you're doing
#' # you can still access this libcurl option:
#' req <- request("https://example.com") %>%
#'   req_options(ssl_verifypeer = 0)
req_options <- function(.req, ...) {
  check_request(.req)

  .req$options <- modify_list(.req$options, ...)
  .req
}

#' Set user-agent for a request
#'
#' This overrides the default user-agent set by httr2 which includes the
#' version numbers of httr2, the curl package, and libcurl.
#'
#' @inheritParams req_perform
#' @param string String to be sent in the `User-Agent` header. If `NULL`,
#'   will user default.
#' @returns A modified HTTP [request].
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
#'   req_user_agent("MyPackage (http://mypackage.com)") %>%
#'   req_dry_run()
req_user_agent <- function(req, string = NULL) {
  check_request(req)

  if (is.null(string)) {
    versions <- c(
      httr2 = utils::packageVersion("httr2"),
      `r-curl` = utils::packageVersion("curl"),
      libcurl = curl::curl_version()$version
    )
    string <- paste0(names(versions), "/", versions, collapse = " ")
  } else {
    check_string(string)
  }

  req_options(req, useragent = string)
}

#' Set time limit for a request
#'
#' An error will be thrown if the request does not complete in the time limit.
#'
#' @inheritParams req_perform
#' @param seconds Maximum number of seconds to wait
#' @returns A modified HTTP [request].
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


#' Use a proxy for a request
#'
#' @inheritParams req_perform
#' @param url,port Location of proxy.
#' @param username,password Login details for proxy, if needed.
#' @param auth Type of HTTP authentication to use. Should be one of the
#'   following: `basic`, digest, digest_ie, gssnegotiate, ntlm, any.
#' @examples
#' # Proxy from https://www.proxynova.com/proxy-server-list/
#' \dontrun{
#' request("http://hadley.nz") %>%
#'   req_proxy("20.116.130.70", 3128) %>%
#'   req_perform()
#' }
#' @export
req_proxy <- function(req, url, port = NULL, username = NULL, password = NULL, auth = "basic") {

  if (!is.null(username) || !is.null(password)) {
    proxyuserpwd <- paste0(username, ":", password)
  } else {
    proxyuserpwd <- NULL
  }

  if (!is.null(port)) {
    if (!is_integerish(port)) {
      abort("`port` must be a number")
    }
  }

  req_options(
    req,
    proxy = url,
    proxyport = port,
    proxyuserpwd = proxyuserpwd,
    proxyauth = auth_flags(auth)
  )
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
#'   body is compressed, this will show the number of bytes received in
#'   each "chunk".
#' @param info Show informational text from curl? This is mainly useful
#'   for debugging https and auth problems, so is disabled by default.
#' @param redact_headers Redact confidential data in the headers? Currently
#'   redacts the contents of the Authorization header to prevent you from
#'   accidentally leaking credentials when debugging/reprexing.
#' @seealso [req_perform()] which exposes a limited subset of these options
#'   through the `verbosity` argument and [with_verbosity()] which allows you
#'   to control the verbosity of requests deeper within the call stack.
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' # Use `req_verbose()` to see the headers that are sent back and forth when
#' # making a request
#' resp <- request("https://httr2.r-lib.org") %>%
#'   req_verbose() %>%
#'   req_perform()
#'
#' # Or use one of the convenient shortcuts:
#' resp <- request("https://httr2.r-lib.org") %>%
#'   req_perform(verbosity = 1)
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

auth_flags <- function(x = "basic") {
  constants <- c(
    basic = 1,
    digest = 2,
    gssnegotiate = 4,
    ntlm = 8,
    digest_ie = 16,
    any = -17
  )
  idx <- arg_match0(x, names(constants), arg_nm = "auth", error_call = caller_env())
  constants[[idx]]
}
