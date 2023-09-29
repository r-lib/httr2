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
the$throttle <- list()
the$cache_throttle <- list()
the$token_cache <- new_environment()
the$last_response <- NULL
the$last_request <- NULL
the$last_multi_responses <- NULL
the$last_chunk_idx <- NULL
the$last_chunks <- NULL
