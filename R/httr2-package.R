#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import R6
#' @import rlang
#' @importFrom glue glue
#' @importFrom lifecycle deprecated
## usethis namespace: end
NULL

the <- new_environment()
the$throttle <- new_environment()
the$breaker <- new_environment()
the$cache_throttle <- list()
the$token_cache <- new_environment()
the$last_response <- NULL
the$last_request <- NULL
the$pool_pollers <- new_environment()
