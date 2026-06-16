sync_req <- function(name, .env = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("nanonext")

  if (missing(name) || !is.character(name)) {
    cli::cli_abort(
      "Use unique (character) name for each sync_req() / sync_rep() pair"
    )
  }
  connected <- FALSE
  cv <- nanonext::cv()
  sock <- nanonext::socket("req")
  withr::defer(close(sock), envir = .env)
  nanonext::pipe_notify(sock, cv, add = TRUE)
  nanonext::listen(sock, url = sprintf("ipc:///tmp/nanonext%s", name))

  function(resp, timeout = 1000L) {
    if (!connected) {
      nanonext::until(cv, timeout)
      connected <<- TRUE
    }
    nanonext::send(sock, 0L, mode = 2L, block = timeout)
    wait_for_http_data(resp, timeout / 1000)
  }
}

sync_rep <- function(name, .env = parent.frame()) {
  if (missing(name) || !is.character(name)) {
    cli::cli_abort(
      "Use unique (character) name for each sync_req() / sync_rep() pair"
    )
  }

  connected <- FALSE
  cv <- nanonext::cv()
  sock <- nanonext::socket("rep")
  withr::defer(close(sock), envir = .env)
  nanonext::pipe_notify(sock, cv, add = TRUE)
  nanonext::dial(sock, url = sprintf("ipc:///tmp/nanonext%s", name))

  function(expr = {}, timeout = 1000L) {
    if (!connected) {
      nanonext::until(cv, timeout)
      connected <<- TRUE
    }
    nanonext::recv(sock, mode = 8L, block = timeout)
    expr
  }
}

# Blocks (by polling the connection) until the next chunk of body data has
# arrived, or the stream is complete, so that a subsequent non-blocking
# resp_stream_lines()/resp_stream_sse() read can see it. Used both for the
# initial chunk a server sends before any sync() signal and for the chunks a
# sync() signal releases.
wait_for_http_data <- function(resp, timeout_s = 5) {
  if (resp$body$is_complete()) {
    return(invisible(TRUE))
  }

  deadline <- as.double(Sys.time()) + timeout_s
  poll_interval <- 0.01

  while (as.double(Sys.time()) < deadline) {
    chunk <- resp$body$read(256)
    if (length(chunk) > 0) {
      resp$cache$push_back <- c(resp$cache$push_back, chunk)
      return(invisible(TRUE))
    }

    if (resp$body$is_complete()) {
      return(invisible(TRUE))
    }

    remaining <- deadline - as.double(Sys.time())
    if (remaining > 0) {
      Sys.sleep(poll_interval)
    }
  }

  invisible(FALSE)
}

# Blocks (by polling the connection) until the stream is complete, i.e. the
# server has closed the connection. A sync() signal only guarantees the last
# chunk's *data* has arrived; the EOF that marks completion can lag behind it.
# Use this before a final read that depends on completion, such as flushing a
# trailing line that has no terminator.
wait_for_complete <- function(resp, timeout_s = 5) {
  deadline <- as.double(Sys.time()) + timeout_s

  repeat {
    chunk <- resp$body$read(256)
    if (length(chunk) > 0) {
      resp$cache$push_back <- c(resp$cache$push_back, chunk)
    }

    if (resp$body$is_complete()) {
      return(invisible(TRUE))
    }

    if (as.double(Sys.time()) >= deadline) {
      return(invisible(FALSE))
    }

    Sys.sleep(0.01)
  }
}
