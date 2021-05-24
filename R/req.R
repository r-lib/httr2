req <- function(base_url) {
  new_req(base_url)
}

new_req <- function(url, headers = list(), body = list(), options = list()) {
  url <- httr::parse_url(url)

  structure(
    list(
      url = url,
      headers = headers,
      body = body,
      options = options
    ),
    class = "httr2_req"
  )
}
