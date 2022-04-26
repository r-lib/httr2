req_policies <- function(.req, ...) {
  check_request(.req)
  .req$policies <- modify_list_dots(.req$policies, ...)
  .req
}

req_policy_exists <- function(req, name) {
  has_name(req$policies, name)
}

req_policy_call <- function(req, name, args, default) {
  if (req_policy_exists(req, name)) {
    exec(req$policies[[name]], !!!args)
  } else {
    if (is_function(default)) {
      exec(default, !!!args)
    } else {
      default
    }
  }
}

as_callback <- function(x, n, name) {
  if (is.null(x)) {
    return(x)
  }

  x <- as_function(x)
  if (!inherits(x, "rlang_lambda_function") && length(formals(x)) != n) {
    abort(glue("Callback {name}() must have {n} argument"))
  }
  x
}
