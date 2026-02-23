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

wait_for_http_data <- function(resp, timeout_s) {
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
