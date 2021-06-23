#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import rlang
#' @importFrom glue glue
## usethis namespace: end
NULL

the <- new_environment()
the$throttle <- list()
the$token_cache <- new_environment()
the$last_response <- NULL
the$last_request <- NULL
