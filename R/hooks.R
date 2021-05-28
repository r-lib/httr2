req_fetch_retry <- function(req, path = NULL, handle = NULL) {
  handle <- handle %||% req_handle(req)

  max_tries <- retry_max_tries(req)
  deadline <- retry_deadline(req)

  i <- 0
  delay <- throttle_delay(req)

  while(i < max_tries && Sys.time() < deadline) {
    sys_sleep(delay)
    resp <- req_fetch_safely(req, path = path, handle = handle)

    if (is_condition(resp)) {
      i <- i + 1
      delay <- retry_backoff(req, i)
    } else if (retry_is_transient(req, resp)) {
      i <- i + 1
      delay <- retry_after(req, resp) %||% retry_backoff(req, i)
    # } else if (auth_needs_reauth(req, resp)) {
    #   req <- auth_reauth(req)
    #   handle <- req_handle(req)
    } else {
      # done
      break
    }
  }

  if (is_condition(resp)) {
    stop(resp)
  } else {
    resp
  }
}

# helpers -----------------------------------------------------------------

req_fetch_safely <- function(req, path = NULL, handle = NULL) {
  # TODO: PR to curl so can specifically catch curl errors
  tryCatch(
    req_fetch(req, path = path, handle = handle),
    error = function(err) err
  )
}
