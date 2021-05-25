
req <- function(base_url) {
  req <- new_req(base_url)
  req <- req_headers_set(req,
    Accept = "application/json, text/xml, application/xml, */*"
  )
  req <- req_user_agent(req, default_ua())
  req
}

new_req <- function(url, headers = list(), body = list(), fields = list(), options = list()) {
  url <- httr::parse_url(url)

  structure(
    list(
      url = url,
      headers = headers,
      body = body,
      fields = fields,
      options = options
    ),
    class = "httr2_req"
  )
}


default_ua <- function() {
  versions <- c(
    libcurl = curl::curl_version()$version,
    `r-curl` = as.character(utils::packageVersion("curl")),
    httr = as.character(utils::packageVersion("httr"))
  )
  paste0(names(versions), "/", versions, collapse = " ")
}
