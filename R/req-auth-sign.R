
req_auth_sign <- function(req, fun, params) {
  req_policies(req,
    auth_sign = list(
      fun = fun,
      params = params
    )
  )
}
auth_sign <- function(req, reauth = FALSE) {
  if (!req_policy_exists(req, "auth_sign")) {
    return(req)
  }

  exec(req$policies$auth_sign$fun,
    req = req,
    reauth = reauth,
    !!!req$policies$auth_sign$params
  )
}
