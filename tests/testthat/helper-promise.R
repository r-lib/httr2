# promises package test helper
extract_promise <- function(promise, timeout = 30) {
  promise_value <- NULL
  error <- NULL
  promises::then(
    promise,
    onFulfilled = function(value) promise_value <<- value,
    onRejected = function(reason) error <<- reason
  )

  start <- Sys.time()
  while (!later::loop_empty()) {
    if (difftime(Sys.time(), start, units = "secs") > timeout) {
      stop("Waited too long")
    }
    later::run_now(0.01)
  }

  if (!is.null(error)) {
    cnd_signal(error)
  } else {
    promise_value
  }
}
