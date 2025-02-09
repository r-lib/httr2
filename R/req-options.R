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
#' req <- request("https://example.com") |>
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
#' request("http://example.com") |> req_dry_run()
#'
#' request("http://example.com") |> req_user_agent("MyString") |> req_dry_run()
#'
#' # If you're wrapping in an API in a package, it's polite to set the
#' # user agent to identify your package.
#' request("http://example.com") |>
#'   req_user_agent("MyPackage (http://mypackage.com)") |>
#'   req_dry_run()
req_user_agent <- function(req, string = NULL) {
  check_request(req)

  if (is.null(string)) {
    versions <- c(
      httr2 = as.character(utils::packageVersion("httr2")),
      `r-curl` = as.character(utils::packageVersion("curl")),
      libcurl = curl_system_version()
    )
    string <- paste0(names(versions), "/", versions, collapse = " ")
  } else {
    check_string(string)
  }

  req_options(req, useragent = string)
}

curl_system_version <- function() curl::curl_version()$version

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
#' request("http://example.com") |> req_timeout(10)
req_timeout <- function(req, seconds) {
  check_request(req)
  check_number_decimal(seconds)
  if (seconds < 0.001) {
    cli::cli_abort("{.arg seconds} must be >1 ms.")
  }

  req_options(
    req,
    timeout_ms = seconds * 1000,
    # reset value set by curl
    # https://github.com/jeroen/curl/blob/1bcf1ab3/src/handle.c#L159
    connecttimeout = 0
  )
}


#' Use a proxy for a request
#'
#' @inheritParams req_perform
#' @param url,port Location of proxy.
#' @param username,password Login details for proxy, if needed.
#' @param auth Type of HTTP authentication to use. Should be one of the
#'   following: `basic`, `digest`, `digest_ie`, `gssnegotiate`, `ntlm`, `any`.
#' @examples
#' # Proxy from https://www.proxynova.com/proxy-server-list/
#' \dontrun{
#' request("http://hadley.nz") |>
#'   req_proxy("20.116.130.70", 3128) |>
#'   req_perform()
#' }
#' @export
req_proxy <- function(req, url, port = NULL, username = NULL, password = NULL, auth = "basic") {

  if (!is.null(username) || !is.null(password)) {
    proxyuserpwd <- paste0(username, ":", password)
  } else {
    proxyuserpwd <- NULL
  }

  check_number_whole(port, allow_null = TRUE)

  req_options(
    req,
    proxy = url,
    proxyport = port,
    proxyuserpwd = proxyuserpwd,
    proxyauth = auth_flags(auth)
  )
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
