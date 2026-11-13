multipart_response <- function(
  body,
  content_type = "multipart/byteranges; boundary=foo"
) {
  if (is.character(body)) {
    body <- charToRaw(body)
  }
  new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = content_type),
    body = body
  )
}
