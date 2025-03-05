sync_req <- function(name = "default", .env = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("nanonext")

  connected <- FALSE
  cv <- nanonext::cv()
  sock <- nanonext::socket("req")
  withr::defer(nanonext::reap(sock), envir = .env)
  nanonext::pipe_notify(sock, cv, add = TRUE)
  nanonext::listen(sock, url = sprintf("ipc:///tmp/nanonext%s", name))

  function(expr = {}, timeout = 1000L) {
    if (!connected) {
      nanonext::until_(cv, timeout) || stop("req connect: timed out")
      connected <<- TRUE
    }
    ctx <- nanonext::.context(sock)
    saio <- nanonext::send_aio(ctx, 0L, mode = 2L)
    expr
    r <- nanonext::recv_aio(ctx, mode = 8L, timeout = timeout)[]
    nanonext::is_error_value(r) && stop("req sync: ", nanonext::nng_error(r))
  }

}

sync_rep <- function(name = "default", .env = parent.frame()) {
  connected <- FALSE
  cv <- nanonext::cv()
  sock <- nanonext::socket("rep")
  nanonext::pipe_notify(sock, cv, add = TRUE)
  withr::defer(nanonext::reap(sock), envir = .env)
  nanonext::dial(sock, url = sprintf("ipc:///tmp/nanonext%s", name))

  function(expr = {}, timeout = 1000L) {
    if (!connected) {
      nanonext::until_(cv, timeout) || stop("resp connect: timed out")
      connected <<- TRUE
    }
    ctx <- nanonext::.context(sock)
    r <- nanonext::recv_aio(ctx, mode = 8L, timeout = timeout)[]
    nanonext::is_error_value(r) && stop("resp sync: ", nanonext::nng_error(r))
    expr
    nanonext::send(ctx, 0L, mode = 2L, block = TRUE)
  }
}
