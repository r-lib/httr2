
hook_rate_limit <- function(retry_after = NULL) {
  if (is.null(retry_after)) {
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After
    # TODO: add HTTP date parsing
    retry_after <- function(resp) {
      if (!resp_header_exists(resp, "Retry-After")) {
        abort("Response must have `Retry-After` header")
      }
      as.numeric(resp_header(resp, "Retry-After"))
    }
  }

  function(resp, req) {
    if (resp_status(resp) != 429) {
      return()
    }
    val <- retry_after(resp)
    if (is.null(val)) {
      return()
    }

    Sys.sleep(val)
    list(retry = TRUE)
  }
}

# Maybe this can't be a hook?
# * Needs state
# * Needs tryCatch around curl call
hook_retry <- function(max_tries = 4, max_wait_time = 60) {
  i <- 1

  list("hook", public = list(
    i = 1,
    time = NULL,
    initialize = function() {

    },
    reset = function() {
      self$time <- Sys.time()
    },
    post = function(resp, req) {
      if (i > max_tries) {
        return()
      }
    }
  ))
}

hook_throttle <- function(max_requests, timeout, realm = NULL) {
  function(req) {
    realm <- req$url$hostname %||% realm

    val <- the$throttle[[realm]]
    if (is.null(val) || val$reset > Sys.time()) {
      val <- list(reset = Sys.time() + timeout, n = 1)
    } else {
      val <- list(reset = val$reset, n = val$n + 1)
    }

    if (val$n > max_requests) {
      Sys.sleep(val$reset - Sys.time())
    }
    req
  }
}

hook_sign <- function(callback) {
  function(req) {
    callback(req)
  }
}
