local_streaming_response <- function(data, frame = parent.frame()) {
  resp <- response(body = StreamingBody$new(rawConnection(data, "rb")))
  withr::defer(close(resp), envir = frame)
  resp
}

ByteBody <- R6::R6Class(
  "ByteBody",
  inherit = StreamingBody,
  public = list(
    initialize = function(bytes) {
      private$bytes <- bytes
    },
    read = function(n) {
      if (length(private$bytes) == 0L) {
        return(raw())
      }
      out <- private$bytes[[1L]]
      private$bytes <- private$bytes[-1L]
      out
    },
    is_open = function() TRUE,
    is_complete = function() length(private$bytes) == 0L,
    close = function() invisible()
  ),
  private = list(
    bytes = NULL
  )
)

FlakySplitter <- R6::R6Class(
  "FlakySplitter",
  inherit = StreamSplitter,
  public = list(
    failed = FALSE,
    fail_on = NULL,
    initialize = function(fail_on = NULL) {
      self$fail_on <- fail_on
    },
    split = function(buffer) {
      should_fail <- is.null(self$fail_on) || identical(buffer, self$fail_on)
      if (should_fail && !self$failed) {
        self$failed <- TRUE
        cli::cli_abort("Failed to split.")
      }
      list(
        blocks = list(buffer),
        remainder = raw(),
        sizes = length(buffer)
      )
    }
  )
)
