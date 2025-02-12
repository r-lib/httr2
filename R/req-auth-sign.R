
req_auth_sign <- function(req, fun, params, cache) {
  req_policies(req,
    auth_sign = list(
      fun = fun,
      params = params,
      cache = cache
    )
  )
}
auth_sign <- function(req) {
  if (!req_policy_exists(req, "auth_sign")) {
    return(req)
  }

  exec(req$policies$auth_sign$fun,
    req = req,
    cache = req$policies$auth_sign$cache,
    !!!req$policies$auth_sign$params
  )
}

req_auth_clear_cache <- function(req) {
  cache <- req$policies$auth_sign$cache
  if (!is.null(cache)) {
    cache$clear()
    TRUE
  } else {
    FALSE
  }
}
