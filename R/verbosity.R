
#' Temporarily set verbosity for all requests
#'
#' @description
#' `with_verbosity()` and `local_verbosity()` are useful for debugging httr2
#' code buried deep inside another package, because they allow you to change
#' the verbosity when you don't have access to the [req_perform()] call.
#'
#' Both functions work by setting the `httr2_verbosity` option. You can also
#' control verbosity by setting the `HTTR2_VERBOSITY` environment variable,
#' which has lower precedence than the option, but can be more easily changed
#' outside of R.
#'
#' @inheritParams req_perform
#' @param code Code to execture
#' @returns `with_verbosity()` returns the result of evaluating `code`.
#'   `local_verbosity()` is called for its side-effect and invisibly returns
#'   the previous value of the option.
#' @export
#' @examples
#' fun <- function() {
#'   request("https://httr2.r-lib.org") |> req_perform()
#' }
#' with_verbosity(fun())
#'
#' fun <- function() {
#'   local_verbosity(2)
#'   # someotherpackage::fun()
#' }
with_verbosity <- function(code, verbosity = 1) {
  withr::local_options(httr2_verbosity = verbosity)
  code
}

#' @export
#' @rdname with_verbosity
#' @inheritParams local_mocked_responses
local_verbosity <- function(verbosity, env = caller_env()) {
  withr::local_options(httr2_verbosity = verbosity, .local_envir = env)
}

httr2_verbosity <- function() {
  x <- getOption("httr2_verbosity")
  if (!is.null(x)) {
    return(x)
  }

  x <- Sys.getenv("HTTR2_VERBOSITY")
  if (nzchar(x)) {
    return(as.integer(x))
  }

  # Hackish fallback for httr::with_verbose
  old <- getOption("httr_config")
  if (!is.null(old$options$debugfunction)) {
    1
  } else {
    0
  }
}
