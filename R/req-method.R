#' Set HTTP method in request
#'
#' Use this function to use a custom HTTP method like `HEAD`,
#' `DELETE`, `PATCH`, `UPDATE`, or `OPTIONS`. The default method is
#' `GET` for requests without a body, and `POST` for requests with a body.
#'
#' @inheritParams req_perform
#' @param method Custom HTTP method
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' request(example_url()) |> req_method("PATCH")
#' request(example_url()) |> req_method("PUT")
#' request(example_url()) |> req_method("HEAD")
req_method <- function(req, method) {
  check_request(req)
  check_string(method)

  req$method <- toupper(method)
  req
}

# Used in req_handle
req_method_apply <- function(req) {
  if (is.null(req$method)) {
    return(req)
  }

  switch(
    req$method,
    HEAD = req_options(req, nobody = TRUE),
    req_options(req, customrequest = req$method)
  )
}

#' Get request method
#'
#' Defaults to `GET`, unless the request has a body, in which case it uses
#' `POST`. Either way the method can be overridden with [req_method()].
#'
#' @inheritParams req_perform
#' @export
#' @examples
#' req <- request(example_url())
#' req_get_method(req)
#' req_get_method(req |> req_body_raw("abc"))
#' req_get_method(req |> req_method("DELETE"))
#' req_get_method(req |> req_method("HEAD"))
req_get_method <- function(req) {
  # https://everything.curl.dev/libcurl-http/requests#request-method
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

# shim so httptest2 doesn't fail
req_method_get <- req_get_method
