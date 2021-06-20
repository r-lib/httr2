#' Set HTTP method
#'
#' Use this function to use a custom HTTP method like "HEAD",
#' "DELETE", "PATCH", "UPDATE", or "OPTIONS".
#'
#' @inheritParams req_fetch
#' @param method Custom HTTP method
#' @export
#' @examples
#' request("http://httpbin.org") %>% req_method("PATCH")
#' request("http://httpbin.org") %>% req_method("PUT")
#' request("http://httpbin.org") %>% req_method("HEAD")
req_method <- function(req, method) {
  check_request(req)
  check_string(method, "`method`")

  req$method <- toupper(method)
  req
}

# Used in req_handle
req_method_apply <- function(req) {
  if (is.null(req$method)) {
    return(req)
  }

  switch(req$method,
    HEAD = req_options(req, nobody = TRUE),
    req_options(req, customrequest = req$method)
  )
}

# Guess the method that curl will used based on options
# https://everything.curl.dev/libcurl-http/requests#request-method
req_method_get <- function(req) {
  if (!is.null(req$method)) {
    req$method
  } else if (has_name(req$options, "nobody")) {
    "HEAD"
  } else if (!is.null(req$body)) {
    "POST"
  } else {
    "GET"
  }
}