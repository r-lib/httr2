req_policies <- function(.req, ..., error_call = caller_env()) {
  check_request(.req, call = error_call)
  .req$policies <- modify_list(.req$policies, ..., error_call = error_call)
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

as_callback <- function(x, n, name, error_call = caller_env()) {
  if (is.null(x)) {
    return(x)
  }

  x <- as_function(x)
  if (!inherits(x, "rlang_lambda_function") && length(formals(x)) != n) {
    cli::cli_abort(
      "Callback {.fn name} must have {n} argument{?s}",
      call = error_call
    )
  }
  x
}
