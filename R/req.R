#' Create a new HTTP request
#'
#' To perform a HTTP request, first create a request object with `req()`,
#' then define its behaviour with `req_` functions, then perform the request
#' and fetch the response with [req_fetch()].
#'
#' @param base_url Base URL for request.
#' @export
#' @examples
#' req("http://r-project.org")
req <- function(base_url) {
  req <- new_request(base_url)
  req <- req_headers_set(req,
    Accept = "application/json, text/xml, application/xml, */*"
  )
  req <- req_user_agent(req, default_ua())
  req
}

#' @export
print.httr2_request <- function(x, ...) {
  cli::cli_text("{.cls {class(x)}}")
  cli::cli_text("{.field URL}: {x$url}")

  bullets_with_header("Headers:", x$headers)
  bullets_with_header("Options:", x$options)
  bullets_with_header("Fields:", x$fields)

  invisible(x)
}

new_request <- function(url, headers = list(), body = list(), fields = list(), options = list()) {
  if (!is_string(url)) {
    abort("`url` must be a string")
  }

  structure(
    list(
      url = url,
      headers = headers,
      body = body,
      fields = fields,
      options = options
    ),
    class = "httr2_request"
  )
}

default_ua <- function() {
  versions <- c(
    httr2 = as.character(utils::packageVersion("httr2")),
    `r-curl` = as.character(utils::packageVersion("curl")),
    libcurl = curl::curl_version()$version
  )
  paste0(names(versions), "/", versions, collapse = " ")
}
