sync_req <- function(name = "default", .env = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("nanonext")

  sock <- nanonext::socket("req", listen = sprintf("ipc:///tmp/%s", name))
  withr::defer(nanonext::reap(sock), envir = .env)

  function(expr = {}, timeout = 1000L) {
    ctx <- nanonext::.context(sock)
    saio <- nanonext::send_aio(ctx, 0L, mode = 2L)
    expr
    nanonext::recv_aio(ctx, mode = 8L, timeout = timeout)[]
  }
}

sync_rep <- function(name = "default", .env = parent.frame()) {
  sock <- nanonext::socket("rep", dial = sprintf("ipc:///tmp/%s", name))
  withr::defer(nanonext::reap(sock), envir = .env)

  function(expr = {}, timeout = 1000L) {
    ctx <- nanonext::.context(sock)
    nanonext::recv_aio(ctx, mode = 8L, timeout = timeout)[]
    expr
    nanonext::send(ctx, 0L, mode = 2L, block = TRUE)
  }
}
