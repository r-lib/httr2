
req_fetch <- function(req, method = NULL) {
  url <- req_url_get(req)
  handle <- req_handle(req, method)

  res <- curl::curl_fetch_memory(url, handle)

  new_response(
    url = res$url,
    status_code = res$status_code,
    type = httr::parse_media(res$type),
    headers = curl::parse_headers_list(res$headers),
    body = res$content,
    times = res$times
  )
}


req_handle <- function(req, method = NULL) {
  if (!is.null(method)) {
    req <- req_method_set(req, method)
  }

  handle <- curl::new_handle()
  curl::handle_setheaders(handle, .list = req$headers)
  curl::handle_setopt(handle, .list = req$options)
  handle
}

req_method_set <- function(req, method) {
  method <- toupper(method)

  # First reset all options - this still needs more thought since
  # calling req_body_none() and then req_method_set(, "POST") will
  # undo the desired effect. Maybe reserve engineer current and only
  # set if different? Maybe set up full from -> to matrix.
  req$options$httpget <- NULL
  req$options$post <- NULL
  req$options$nobody <- NULL
  req$options$customrequest <- NULL

  switch(method,
    GET = req_options_set(req, httpget = TRUE),
    POST = req_options_set(req, post = TRUE),
    HEAD = req_options_set(req, nobody = TRUE),
    req_options_set(req, customrequest = method)
  )
}

req_fetch <- function(req, method = NULL) {
  url <- req_url_get(req)
  handle <- req_handle(req, method)

  res <- curl::curl_fetch_memory(url, handle)

  new_response(
    url = res$url,
    status_code = res$status_code,
    type = httr::parse_media(res$type),
    headers = curl::parse_headers_list(res$headers),
    body = res$content,
    times = res$times
  )
}


req_handle <- function(req, method = NULL) {
  if (!is.null(method)) {
    req <- req_method_set(req, method)
  }

  handle <- curl::new_handle()
  curl::handle_setheaders(handle, .list = req$headers)
  curl::handle_setopt(handle, .list = req$options)
  handle
}

req_method_set <- function(req, method) {
  method <- toupper(method)

  # First reset all options - this still needs more thought since
  # calling req_body_none() and then req_method_set(, "POST") will
  # undo the desired effect. Maybe reserve engineer current and only
  # set if different? Maybe set up full from -> to matrix.
  req$options$httpget <- NULL
  req$options$post <- NULL
  req$options$nobody <- NULL
  req$options$customrequest <- NULL

  switch(method,
    GET = req_options_set(req, httpget = TRUE),
    POST = req_options_set(req, post = TRUE),
    HEAD = req_options_set(req, nobody = TRUE),
    req_options_set(req, customrequest = method)
  )
}
