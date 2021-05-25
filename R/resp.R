
new_response <- function(...) {
  structure(list(...), class = "httr2_response")
}

resp_body_is_path <- function(resp) is_path(resp$body)

resp_status <- function(resp) {
  resp$status
}
resp_is_error <- function(resp) {
  resp_status(resp) >= 400
}
