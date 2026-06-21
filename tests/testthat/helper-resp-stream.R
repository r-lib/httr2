local_streaming_response <- function(data, frame = parent.frame()) {
  resp <- response(body = StreamingBody$new(rawConnection(data, "rb")))
  withr::defer(close(resp), envir = frame)
  resp
}
