sync_req <- function(name = "default", .env = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("nanonext")

  connected <- FALSE
  cv <- nanonext::cv()
  sock <- nanonext::socket("req")
  withr::defer(close(sock), envir = .env)
  nanonext::pipe_notify(sock, cv, add = TRUE)
  nanonext::listen(sock, url = sprintf("ipc:///tmp/nanonext%s", name))

  function(expr = {}, timeout = 1000L) {
    if (!connected) {
      nanonext::until(cv, timeout)
      connected <<- TRUE
    }
    ctx <- nanonext::context(sock)
    saio <- nanonext::send_aio(ctx, 0L, mode = 2L)
    expr
    nanonext::call_aio(nanonext::recv_aio(ctx, mode = 8L, timeout = timeout))
  }
}

sync_rep <- function(name = "default", .env = parent.frame()) {
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
    ctx <- nanonext::context(sock)
    nanonext::call_aio(nanonext::recv_aio(ctx, mode = 8L, timeout = timeout))
    expr
    nanonext::send(ctx, 0L, mode = 2L, block = TRUE)
  }
}
