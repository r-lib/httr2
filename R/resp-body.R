
resp_body_raw <- function(resp) {
  resp$body
}

resp_body_string <- function(resp, encoding = NULL) {
  encoding <- encoding %||%
    resp$type$params$charset %||%
    warn_utf()

  iconv(readBin(resp$body, character()), from = encoding, to = "UTF-8")
}

warn_utf <- function() {
  warn("No encoding found; using UTF-8")
  "UTF-8"
}
