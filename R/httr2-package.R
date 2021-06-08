#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import rlang
#' @importFrom glue glue
#' @importFrom lifecycle deprecated
## usethis namespace: end
NULL

the <- new_environment()
the$throttle <- list()
the$token_cache <- new_environment()
