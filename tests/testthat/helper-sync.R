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

  function(
    expr = {
    },
    timeout = 1000L
  ) {
    if (!connected) {
      nanonext::until(cv, timeout)
      connected <<- TRUE
    }
    ctx <- nanonext::context(sock)
    saio <- nanonext::send_aio(ctx, 0L, mode = 2L)
    expr
    nanonext::call_aio(nanonext::recv_aio(ctx, mode = 8L, timeout = timeout))
    nanonext::msleep(50L) # wait, as nanonext messages can return faster than side effects (e.g. stream)
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

  function(
    expr = {
    },
    timeout = 1000L
  ) {
    if (!connected) {
      nanonext::until(cv, timeout)
      connected <<- TRUE
    }
    ctx <- nanonext::context(sock)
    nanonext::call_aio(nanonext::recv_aio(ctx, mode = 8L, timeout = timeout))
    expr
    nanonext::send(ctx, 0L, mode = 2L, block = TRUE)
  }
}
