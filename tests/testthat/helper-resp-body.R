multipart_response <- function(
  body,
  content_type = "multipart/byteranges; boundary=foo"
) {
  new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = content_type),
    body = charToRaw(body)
  )
}
